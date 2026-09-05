#import "MeleePadCoreHost.h"
#import "MeleePadControllerMapping.h"
#import "../shared/MeleePadBenchmarkRoute.h"
#import "MeleePadDiagnostics.h"
#import "MeleePadInputPipeEncoder.h"

#import <AVFAudio/AVFAudio.h>
#import <Metal/Metal.h>
#import <fcntl.h>
#import <pthread.h>
#import <sys/stat.h>
#import <sys/un.h>

#include <atomic>
#include <algorithm>
#include <bit>
#include <cerrno>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <mutex>
#include <string>
#include <thread>

namespace fs = std::filesystem;

/* The ModernGekko runtime header is a C++ header; include it here only. */
#include "moderngekko/runtime.hpp"
#include "netplay_session.hpp"
#include "runtime/dolphin_runtime_internal.hpp"

#include "AudioCommon/Mixer.h"
#include "AudioCommon/SoundStream.h"
#include "Common/FramePhaseTiming.h"
#include "Core/Boot/Boot.h"
#include "Core/Config/CheatSettings.h"
#include "Core/Config/MainSettings.h"
#include "Core/Config/NetplaySettings.h"
#include "Core/Core.h"
#include "Core/Cheats/MemoryWatcherUtils.h"
#include "Core/Config/StaticRecompSettings.h"
#include "Core/Config/GraphicsSettings.h"
#include "Core/HW/Memmap.h"
#include "Core/PowerPC/PowerPC.h"
#include "Core/System.h"
#include "UICommon/UICommon.h"
#include "VideoCommon/PerformanceMetrics.h"
#include "VideoCommon/VideoConfig.h"

static void MeleePadRuntimeLogCallback(
    moderngekko::RuntimeLogLevel level, const char *category,
    const char *message, void *userData) {
    (void)userData;
    @autoreleasepool {
        MeleePadLogRuntimeEvent(
            level == moderngekko::RuntimeLogLevel::Error ? @"error" : @"warning",
            category != nullptr ? @(category) : @"runtime",
            message != nullptr ? @(message) : @"unknown runtime event");
    }
}

static NSString *MeleePadRuntimeUserDirectory(NSString *userDirectory) {
#if TARGET_OS_SIMULATOR
    NSString *override =
        NSProcessInfo.processInfo.environment[@"MELEEPAD_RUNTIME_USER_DIRECTORY"];
    if (override.length == 0)
        return userDirectory;

    NSString *resolvedUser =
        userDirectory.stringByStandardizingPath.stringByResolvingSymlinksInPath;
    NSString *resolvedOverride =
        override.stringByStandardizingPath.stringByResolvingSymlinksInPath;
    NSString *watcherSocket = [override
        stringByAppendingPathComponent:@"MemoryWatcher/MemoryWatcher"];
    BOOL sameDirectory = [resolvedOverride isEqualToString:resolvedUser];
    BOOL socketFits = strlen(watcherSocket.fileSystemRepresentation) <
        sizeof(((struct sockaddr_un *)0)->sun_path);
    if (sameDirectory && socketFits) {
        MeleePadLog(@"runtime user-directory override enabled source=simulator-diagnostic");
        return override;
    }

    MeleePadLog(@"runtime user-directory override rejected sameDirectory=%d socketFits=%d",
              sameDirectory, socketFits);
#endif
    return userDirectory;
}

static NSString *const MeleePadUnlockAllCodeName = @"$All Characters and Stages";

/* Maintain only MeleePad's named activation in Dolphin's local GameINI. The
 * bundled Action Replay definition remains Dolphin-owned; this file merely
 * selects it. Unrelated user sections and code selections are preserved. */
static BOOL MeleePadConfigureOfflineCheats(NSString *userDirectory,
                                           BOOL unlockAll,
                                           NSError **error) {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *directory = [userDirectory stringByAppendingPathComponent:@"GameSettings"];
    NSString *path = [directory stringByAppendingPathComponent:@"GALE01r0.ini"];
    NSString *existing = [NSString stringWithContentsOfFile:path
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    if (existing == nil && !unlockAll)
        return NO;

    NSMutableArray<NSString *> *output = [NSMutableArray array];
    NSArray<NSString *> *lines = [(existing ?: @"")
        componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
    BOOL inActionReplayEnabled = NO;
    BOOL inAnyEnabledSection = NO;
    BOOL foundActionReplayEnabled = NO;
    BOOL insertedUnlock = NO;
    BOOL hasEnabledCode = NO;

    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];
        BOOL isSection = [trimmed hasPrefix:@"["] && [trimmed hasSuffix:@"]"];
        if (isSection) {
            if (inActionReplayEnabled && unlockAll && !insertedUnlock) {
                [output addObject:MeleePadUnlockAllCodeName];
                insertedUnlock = YES;
                hasEnabledCode = YES;
            }
            inActionReplayEnabled = [trimmed isEqualToString:@"[ActionReplay_Enabled]"];
            inAnyEnabledSection = inActionReplayEnabled ||
                [trimmed isEqualToString:@"[Gecko_Enabled]"];
            foundActionReplayEnabled |= inActionReplayEnabled;
            [output addObject:line];
            continue;
        }
        if (inActionReplayEnabled &&
            [trimmed isEqualToString:MeleePadUnlockAllCodeName]) {
            // Reinsert exactly once below when the preference is enabled.
            continue;
        }
        if (inAnyEnabledSection && [trimmed hasPrefix:@"$"])
            hasEnabledCode = YES;
        [output addObject:line];
    }

    if (inActionReplayEnabled && unlockAll && !insertedUnlock) {
        [output addObject:MeleePadUnlockAllCodeName];
        insertedUnlock = YES;
        hasEnabledCode = YES;
    } else if (unlockAll && !foundActionReplayEnabled) {
        if (output.count > 0 && ((NSString *)output.lastObject).length > 0)
            [output addObject:@""];
        [output addObject:@"[ActionReplay_Enabled]"];
        [output addObject:MeleePadUnlockAllCodeName];
        hasEnabledCode = YES;
    }

    NSString *updated = [output componentsJoinedByString:@"\n"];
    if ([updated isEqualToString:existing])
        return hasEnabledCode;
    if (![fileManager createDirectoryAtPath:directory
                withIntermediateDirectories:YES attributes:nil error:error])
        return NO;
    if (![updated writeToFile:path atomically:YES
                     encoding:NSUTF8StringEncoding error:error])
        return NO;
    return hasEnabledCode;
}

static NSString *MeleePadNetplayFailureMessage(moderngekko::frontend::NetplayExitCode failure) {
    using moderngekko::frontend::NetplayExitCode;
    switch (failure) {
    case NetplayExitCode::InvalidConfiguration:
        return @"The selected game data or controller configuration is invalid.";
    case NetplayExitCode::HostUnavailable:
        return @"The host could not be reached. Check the address, port, and network.";
    case NetplayExitCode::VersionMismatch:
        return @"The other player is using a different MeleePad netplay version.";
    case NetplayExitCode::CompatibilityMismatch:
        return @"The game revision, module, or synchronized settings do not match.";
    case NetplayExitCode::RoomFull:
    case NetplayExitCode::ServerFull:
        return @"That lobby is full.";
    case NetplayExitCode::GameRunning:
        return @"That lobby has already started a match.";
    case NetplayExitCode::NicknameRejected:
        return @"The nickname was rejected. Use 1–20 characters.";
    case NetplayExitCode::Failed:
    default:
        return @"Online Play could not start.";
    }
}

@interface MeleePadCoreHost ()
- (void)applyAspectRatioMode:(MeleePadAspectRatioMode)mode source:(NSString *)source;
- (MeleePadBenchmarkGuestState)benchmarkGuestState;
- (BOOL)setBenchmarkRandomSeed:(u32)seed previousValue:(u32 *)previousValue;
- (BOOL)setBenchmarkForcedStage:(u8)stageId previousValue:(u8 *)previousValue;
- (BOOL)setBenchmarkFourPlayerRosterPreviousValue:(u32 *)previousValue;
- (void)applySystemPauseState;
- (void)scheduleSystemStateRetry;
- (void)handleAudioSessionInterruption:(NSNotification *)notification;
@end

@implementation MeleePadCoreHost {
    CAMetalLayer *_layer;
    std::thread *_gameThread;
    std::atomic<bool> *_stopRequested;
    std::atomic<bool> *_starting;
    std::atomic<bool> *_running;
    std::atomic<bool> *_modernCStickHorizontal;
    std::atomic<bool> *_allowOfflineCheats;
    std::mutex *_runtimeMutex;
    moderngekko::Runtime *_runtime;
    int _pipeFd;
    void (^_onError)(NSString *);
    BOOL _applicationActive;
    BOOL _audioInterrupted;
    BOOL _runtimePausedForSystemEvent;
    BOOL _audioSessionDeactivatedForSystemEvent;
    BOOL _audioSessionNeedsReactivation;
    BOOL _systemStateRetryScheduled;
    NSUInteger _systemStateRetryAttempts;
    NSString *_activePerformanceProfile;
    NSString *_activePerformanceSource;
    NSString *_activeFrameMode;
    unsigned long long _moduleFileSize;
    dispatch_queue_t _netplayQueue;
    std::unique_ptr<moderngekko::frontend::NetplaySession> *_netplaySession;
    BOOL *_netplayServicesActive;
    BOOL *_netplayBootInstalled;
    NSString *_lastGameRoot;
    NSString *_lastDiscImagePath;
    NSString *_lastModulePath;
    NSString *_lastUserDirectory;
}

- (instancetype)initWithLayer:(CAMetalLayer *)layer {
    if ((self = [super init])) {
        _layer = layer;
        _pipeFd = -1;
        _gameThread = new std::thread();
        _stopRequested = new std::atomic<bool>(false);
        _starting = new std::atomic<bool>(false);
        _running = new std::atomic<bool>(false);
        _modernCStickHorizontal = new std::atomic<bool>(
            [MeleePadSettings sharedSettings].modernCStickHorizontal);
        _allowOfflineCheats = new std::atomic<bool>(true);
        _runtimeMutex = new std::mutex();
        _runtime = nullptr;
        _applicationActive = UIApplication.sharedApplication.applicationState == UIApplicationStateActive;
        _audioInterrupted = NO;
        _runtimePausedForSystemEvent = NO;
        _audioSessionDeactivatedForSystemEvent = NO;
        _audioSessionNeedsReactivation = NO;
        _systemStateRetryScheduled = NO;
        _systemStateRetryAttempts = 0;
        _activePerformanceProfile = @"not started";
        _activePerformanceSource = @"none";
        _activeFrameMode = @"not started";
        _moduleFileSize = 0;
        _netplayQueue = dispatch_queue_create("com.meleepad.netplay-session", DISPATCH_QUEUE_SERIAL);
        _netplaySession = new std::unique_ptr<moderngekko::frontend::NetplaySession>();
        _netplayServicesActive = new BOOL(NO);
        _netplayBootInstalled = new BOOL(NO);
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(handleAudioSessionInterruption:)
                   name:AVAudioSessionInterruptionNotification
                 object:AVAudioSession.sharedInstance];
    }
    return self;
}

- (BOOL)isRunning {
    return _running->load();
}

- (void)startWithGameRoot:(NSString *)gameRoot
            discImagePath:(NSString *)discImagePath
               modulePath:(NSString *)modulePath
             userDirectory:(NSString *)userDirectory
                   onError:(void (^)(NSString *))onError {
    if (_running->load() || _starting->load() || _gameThread->joinable())
        return;
    _lastGameRoot = [gameRoot copy];
    _lastDiscImagePath = [discImagePath copy];
    _lastModulePath = [modulePath copy];
    _lastUserDirectory = [userDirectory copy];
    _onError = [onError copy];
    *_stopRequested = false;
    *_starting = true;

    NSError *audioSessionError = nil;
    AVAudioSession *audioSession = AVAudioSession.sharedInstance;
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError];
    if (!audioSessionError)
        [audioSession setActive:YES error:&audioSessionError];
    if (audioSessionError)
        MeleePadLog(@"audio session setup failed: %@", audioSessionError);
    else
        MeleePadLog(@"audio session active route=%@", audioSession.currentRoute.outputs.firstObject.portType ?: @"none");

    NSString *pipeDir = [userDirectory stringByAppendingPathComponent:@"Pipes"];
    NSString *pipePath = [pipeDir stringByAppendingPathComponent:@"meleepad"];
    [[NSFileManager defaultManager] createDirectoryAtPath:pipeDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    // The runtime opens the FIFO read-only; recreate if a stale file exists.
    ::unlink(pipePath.fileSystemRepresentation);
    int fifoResult = ::mkfifo(pipePath.fileSystemRepresentation, 0666);
    MeleePadLog(@"input pipe create result=%d errno=%d", fifoResult, fifoResult == 0 ? 0 : errno);

    // This is a dedicated virtual GameCube controller. Dolphin's pipe backend
    // is present in the iOS core, but it has no default bindings, so provide
    // its stable mapping before the runtime initializes controllers.
    NSString *configDirectory = [userDirectory stringByAppendingPathComponent:@"Config"];
    [[NSFileManager defaultManager] createDirectoryAtPath:configDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    NSString *padConfig =
        @"[GCPad1]\n"
         "Device = Pipe/0/meleepad\n"
         "Buttons/A = `Button A`\n"
         "Buttons/B = `Button B`\n"
         "Buttons/X = `Button X`\n"
         "Buttons/Y = `Button Y`\n"
         "Buttons/Z = `Button Z`\n"
         "Buttons/Start = `Button START`\n"
         "Main Stick/Up = `Axis MAIN Y -`\n"
         "Main Stick/Down = `Axis MAIN Y +`\n"
         "Main Stick/Left = `Axis MAIN X -`\n"
         "Main Stick/Right = `Axis MAIN X +`\n"
         "Main Stick/Calibration = 100.00\n"
         "C-Stick/Up = `Axis C Y -`\n"
         "C-Stick/Down = `Axis C Y +`\n"
         "C-Stick/Left = `Axis C X -`\n"
         "C-Stick/Right = `Axis C X +`\n"
         "C-Stick/Calibration = 100.00\n"
         "Triggers/L = `Axis L +`\n"
         "Triggers/R = `Axis R +`\n"
         "Triggers/L-Analog = `Axis L +`\n"
         "Triggers/R-Analog = `Axis R +`\n"
         "D-Pad/Up = `Button D_UP`\n"
         "D-Pad/Down = `Button D_DOWN`\n"
         "D-Pad/Left = `Button D_LEFT`\n"
         "D-Pad/Right = `Button D_RIGHT`\n"
         "Options/Always Connected = True\n";
    [padConfig writeToFile:[configDirectory stringByAppendingPathComponent:@"GCPadNew.ini"]
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:nil];

    MeleePadLog(@"runtime thread starting discImage=%d moduleExists=%d",
              discImagePath.length > 0,
              [[NSFileManager defaultManager] fileExistsAtPath:modulePath]);
    _moduleFileSize = [[[NSFileManager defaultManager]
        attributesOfItemAtPath:modulePath error:nil][NSFileSize] unsignedLongLongValue];
    *_gameThread = std::thread([self, gameRoot, discImagePath, modulePath, userDirectory] {
        [self runGameWithGameRoot:gameRoot
                    discImagePath:discImagePath
                       modulePath:modulePath
                    userDirectory:userDirectory];
    });
}

- (void)runGameWithGameRoot:(NSString *)gameRoot
              discImagePath:(NSString *)discImagePath
                 modulePath:(NSString *)modulePath
              userDirectory:(NSString *)userDirectory {
    std::string errorMessage;
    @autoreleasepool {
        NSString *runtimeUserDirectory = MeleePadRuntimeUserDirectory(userDirectory);
        const BOOL offlineCheatsAllowed =
            _allowOfflineCheats->load(std::memory_order_acquire);
        const BOOL unlockAll = offlineCheatsAllowed &&
            [MeleePadSettings sharedSettings].unlockAllCharactersAndStages;
        NSError *cheatConfigError = nil;
        const BOOL hasEnabledOfflineCode = MeleePadConfigureOfflineCheats(
            runtimeUserDirectory, unlockAll, &cheatConfigError);
        if (cheatConfigError != nil) {
            MeleePadLog(@"offline cheat configuration failed: %@",
                      cheatConfigError.localizedDescription);
        } else {
            MeleePadLog(@"offline cheat configuration allowed=%d unlockAll=%d enabledCodes=%d",
                      offlineCheatsAllowed, unlockAll, hasEnabledOfflineCode);
        }
        moderngekko::RuntimeConfig config;
        config.game_root = gameRoot.fileSystemRepresentation;
        if (discImagePath.length > 0)
            config.disc_image = discImagePath.fileSystemRepresentation;
        config.user_directory = runtimeUserDirectory.fileSystemRepresentation;
        config.graphics.backend = "Metal";
        config.headless = false;
        config.show_fps_in_title = false;
        config.log_callback = MeleePadRuntimeLogCallback;
        // Melee is natively a 60 FPS title. The GMSE01-only Sunshine frame
        // patch must never be exposed or enabled by MeleePad.
        config.enable_gmse01_60fps = false;
        NSArray<NSString *> *arguments = NSProcessInfo.processInfo.arguments;
        BOOL launchArgumentPerformance90 = [arguments
            containsObject:@"-meleepadExperimentalPerformanceMode"];
        BOOL launchArgumentPerformance95 = [arguments
            containsObject:@"-meleepadExperimentalPerformance95"];
        BOOL launchArgumentPerformanceQoSOnly = [arguments
            containsObject:@"-meleepadExperimentalPerformanceQoSOnly"];
        NSString *performanceProfile = @"stable";
        NSString *performanceSource = @"default";
        float emulatedCPUClock = 1.00f;
        BOOL useExperimentalQoS = NO;
        if (launchArgumentPerformanceQoSOnly) {
            performanceProfile = @"experimental-qos-only-100";
            performanceSource = @"launch argument";
            useExperimentalQoS = YES;
        } else if (launchArgumentPerformance95) {
            performanceProfile = @"experimental-single-core-95";
            performanceSource = @"launch argument";
            emulatedCPUClock = 0.95f;
            useExperimentalQoS = YES;
        } else if (launchArgumentPerformance90) {
            performanceProfile = @"experimental-single-core-90";
            performanceSource = @"launch argument";
            emulatedCPUClock = 0.90f;
            useExperimentalQoS = YES;
        }

        if (emulatedCPUClock < 1.00f)
            config.emulated_cpu_clock_scale = emulatedCPUClock;
        int qosResult = 0;
        if (useExperimentalQoS)
            qosResult = pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0);
        if (useExperimentalQoS) {
            MeleePadLog(@"runtime performance profile=%@ cpuVideoSplit=1 syncGPU=1 syncGPUMaxDistance=1000000 shaderCompilerThreads=3 emulatedCPUClock=%.2f gameThreadQoS=userInitiated qosResult=%d source=%@",
                      performanceProfile, emulatedCPUClock, qosResult, performanceSource);
        } else {
            MeleePadLog(@"runtime performance profile=stable cpuVideoSplit=1 syncGPU=1 syncGPUMaxDistance=1000000 shaderCompilerThreads=3 emulatedCPUClock=1.00 gameThreadQoS=inherited source=default");
        }
        @synchronized (self) {
            _activePerformanceProfile = performanceProfile;
            _activePerformanceSource = performanceSource;
        }
        config.render_surface = (__bridge void *)_layer;
        config.module = moderngekko::ModuleSource::DynamicPath(
            modulePath.fileSystemRepresentation);

        @synchronized (self) {
            _activeFrameMode = @"native-60-fps";
        }
        MeleePadLog(@"runtime frame mode=native 60 FPS source=GALE01");

        auto created = moderngekko::Runtime::Create(std::move(config));
        if (!created) {
            errorMessage = created.error->message;
            *_starting = false;
            MeleePadLog(@"runtime create failed: %s", errorMessage.c_str());
            if (_onError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _onError(@(errorMessage.c_str()));
                });
            }
            return;
        }
        // GALE01's OS scheduler waits here while no guest thread is runnable.
        // ModernGekko's existing idle seam advances to the next emulated event
        // instead of burning the host CPU on the polling loop.
        Config::SetBase(Config::MAIN_STATICRECOMP_IDLE_PC, 0x80348814u);
        // A second scheduler path reaches the same no-runnable-thread poll
        // after enabling interrupts. Preserve both proven revision-1.00
        // boundaries rather than replacing one with the other.
        Config::SetBase(Config::MAIN_STATICRECOMP_SECONDARY_IDLE_PC, 0x80349494u);
        // Melee's raw-controller queue also waits for a periodic alarm. The
        // return address guard prevents other callers of the shared service
        // routine from being treated as idle.
        Config::SetBase(Config::MAIN_STATICRECOMP_CALLER_IDLE_PC, 0x80019550u);
        Config::SetBase(Config::MAIN_STATICRECOMP_CALLER_IDLE_LR, 0x801A4064u);
        MeleePadLog(@"runtime scheduler idle skip=enabled pc=80348814 secondary=80349494 caller=80019550/801A4064");
        // Netplay never runs local codes. Offline boots enable Dolphin's code
        // engine only when the local GameINI contains an enabled selection.
        Config::SetBase(Config::MAIN_ENABLE_CHEATS,
                        offlineCheatsAllowed && hasEnabledOfflineCode);
        MeleePadLog(@"runtime offline cheats active=%d", offlineCheatsAllowed && hasEnabledOfflineCode);
        {
            std::scoped_lock lock(*_runtimeMutex);
            _runtime = created.runtime.get();
        }
        if (_stopRequested->load()) {
            std::scoped_lock lock(*_runtimeMutex);
            _runtime = nullptr;
            *_starting = false;
            return;
        }
        *_starting = false;
        *_running = true;
        MeleePadLog(@"runtime created");
        moderngekko::Runtime *createdRuntime = created.runtime.get();
        dispatch_sync(_netplayQueue, ^{
            if (*self->_netplaySession)
                (*self->_netplaySession)->AttachRuntime(createdRuntime);
        });

        // Apply the persisted render-resolution choice now that the runtime's
        // config layers exist.
        NSNumber *savedScaleValue =
            [[NSUserDefaults standardUserDefaults] objectForKey:@"MeleePadRenderScale"];
        NSInteger savedScale = savedScaleValue ? savedScaleValue.integerValue : 1;
        NSInteger clampedSavedScale = savedScale < 1 ? 1 : (savedScale > 4 ? 4 : savedScale);
        Config::SetCurrent(Config::GFX_EFB_SCALE, static_cast<int>(clampedSavedScale));
        Config::SetCurrent(Config::GFX_MAX_EFB_SCALE, 12);
        MeleePadLog(@"runtime render scale=%ld source=persisted", (long)clampedSavedScale);

        NSNumber *savedAspectValue = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"MeleePadAspectRatioMode"];
        MeleePadAspectRatioMode savedAspect = savedAspectValue ?
            (MeleePadAspectRatioMode)savedAspectValue.integerValue : MeleePadAspectRatioOriginal;
        [self applyAspectRatioMode:savedAspect source:@"persisted"];

        // Open the input FIFO for writing (blocks until the runtime reads it).
        NSString *pipePath = [[userDirectory stringByAppendingPathComponent:@"Pipes"]
            stringByAppendingPathComponent:@"meleepad"];
        for (int attempt = 0; attempt < 600 && !_stopRequested->load(); ++attempt) {
            _pipeFd = ::open(pipePath.fileSystemRepresentation, O_WRONLY | O_NONBLOCK);
            if (_pipeFd >= 0) {
                MeleePadLog(@"input pipe connected attempt=%d", attempt + 1);
                break;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        if (_pipeFd < 0)
            MeleePadLog(@"input pipe unavailable after wait errno=%d stopRequested=%d", errno,
                      _stopRequested->load());

        // Run() marks the ModernGekko runtime active before booting. Re-apply
        // any lifecycle state on the main queue so a resign-active event that
        // arrived during startup cannot be lost.
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_systemStateRetryAttempts = 0;
            [self applySystemPauseState];
        });
        auto result = created.runtime->Run();
        dispatch_sync(_netplayQueue, ^{
            if (*self->_netplaySession) {
                (*self->_netplaySession)->FinishRuntime();
                *self->_netplayBootInstalled = NO;
            }
        });
        if (*_netplaySession && self.onNetplayMatchEnded) {
            dispatch_async(dispatch_get_main_queue(), self.onNetplayMatchEnded);
        }
        {
            std::scoped_lock lock(*_runtimeMutex);
            _runtime = nullptr;
        }
        MeleePadLog(@"runtime exited error=%d stopRequested=%d",
                  (bool)result.error, _stopRequested->load());
        if (result.error && _onError) {
            errorMessage = result.error->message;
            dispatch_async(dispatch_get_main_queue(), ^{
                _onError(@(errorMessage.c_str()));
            });
        }
        if (_pipeFd >= 0) {
            ::close(_pipeFd);
            _pipeFd = -1;
        }
    }
    *_running = false;
    *_starting = false;
}

- (void)publishInput:(MeleePadInputState)input {
    if (_pipeFd < 0)
        return;
    static uint16_t lastButtons = 0;
    static BOOL traceButtonEdges = [] {
        NSString *value = NSProcessInfo.processInfo.environment[@"MELEEPAD_TRACE_BUTTON_EDGES"];
        return value.boolValue;
    }();
    static const char *benchmarkRoute = [] {
        NSString *value = NSProcessInfo.processInfo.environment[@"MELEEPAD_BENCHMARK_ROUTE"];
        return value.length > 0 ? strdup(value.UTF8String) : static_cast<char *>(nullptr);
    }();
    static const auto benchmarkStart = std::chrono::steady_clock::now();
    static std::size_t lastBenchmarkPulse = SIZE_MAX;
    std::size_t benchmarkPulse = SIZE_MAX;
    const double benchmarkWallElapsed = std::chrono::duration<double>(
        std::chrono::steady_clock::now() - benchmarkStart).count();
    const u64 benchmarkEmulatedFrame =
        Common::FramePhaseTiming::GetEmulatedFrameIndex();
    // Phase-logged comparisons drive input from the guest frame counter, so
    // host scheduling and thermal slowdown cannot shift a button edge by a
    // guest frame. Keep wall time as the fallback for lightweight route use.
    const double benchmarkElapsed = benchmarkEmulatedFrame != 0
        ? static_cast<double>(benchmarkEmulatedFrame) / 60.0
        : benchmarkWallElapsed;
    MeleePadBenchmarkGuestState benchmarkGuest = {};
    const bool benchmarkActive = MeleePadApplyBenchmarkRoute(
        benchmarkRoute, benchmarkElapsed, &input, &benchmarkPulse);
    if (benchmarkActive && benchmarkRoute != nullptr) {
        benchmarkGuest = [self benchmarkGuestState];
        MeleePadApplyBenchmarkGuestRoute(benchmarkRoute, benchmarkElapsed,
                                         benchmarkGuest, &input, &benchmarkPulse);
    }
    static std::size_t lastBenchmarkSeedStep = SIZE_MAX;
    const bool benchmarkSeedBoundary = MeleePadBenchmarkShouldFixRandomSeed(
        benchmarkRoute, benchmarkPulse);
    if (benchmarkActive && benchmarkSeedBoundary &&
        benchmarkPulse != lastBenchmarkSeedStep) {
        constexpr u32 kBenchmarkRandomSeed = 0xFAA44507u;
        u32 previousSeed = 0;
        if ([self setBenchmarkRandomSeed:kBenchmarkRandomSeed
                           previousValue:&previousSeed]) {
            lastBenchmarkSeedStep = benchmarkPulse;
            MeleePadLog(@"benchmark random seed fixed step=%s previous=%08x current=%08x",
                      MeleePadBenchmarkStepLabel(benchmarkRoute, benchmarkPulse), previousSeed,
                      kBenchmarkRandomSeed);
        }
    }
    if (benchmarkActive &&
        MeleePadBenchmarkShouldFixFourPlayerRoster(benchmarkRoute, benchmarkGuest)) {
        u32 previousRoster = 0;
        if ([self setBenchmarkFourPlayerRosterPreviousValue:&previousRoster]) {
            MeleePadLog(@"benchmark fixed roster previous=%08x current=10040506",
                      previousRoster);
        }
    }
    static bool benchmarkForcedFountain = false;
    if (benchmarkActive && !benchmarkForcedFountain &&
        MeleePadBenchmarkShouldForceFountain(benchmarkRoute, benchmarkGuest)) {
        constexpr u8 kFountainOfDreamsStageId = 0x0Cu;
        u8 previousStage = 0;
        if ([self setBenchmarkForcedStage:kFountainOfDreamsStageId
                            previousValue:&previousStage]) {
            benchmarkForcedFountain = true;
            MeleePadLog(@"benchmark forced stage previous=%02x current=%02x",
                      previousStage, kFountainOfDreamsStageId);
        }
    }
    static bool benchmarkForcedBigBlue = false;
    if (benchmarkActive && !benchmarkForcedBigBlue &&
        MeleePadBenchmarkShouldForceBigBlue(benchmarkRoute, benchmarkGuest)) {
        constexpr u8 kBigBlueStageId = 0x13u;
        u8 previousStage = 0;
        if ([self setBenchmarkForcedStage:kBigBlueStageId
                            previousValue:&previousStage]) {
            benchmarkForcedBigBlue = true;
            MeleePadLog(@"benchmark forced stage previous=%02x current=%02x",
                      previousStage, kBigBlueStageId);
        }
    }
    if (benchmarkActive &&
        benchmarkPulse != SIZE_MAX && benchmarkPulse != lastBenchmarkPulse) {
        MeleePadLog(@"benchmark route=%s step=%s elapsed=%.3f emulatedFrame=%llu "
                   "gameState=%08x "
                   "cssCursor=%@ cursorPointer=%08x players=%02x/%02x,%02x/%02x,%02x/%02x,%02x/%02x",
                  benchmarkRoute,
                  MeleePadBenchmarkStepLabel(benchmarkRoute, benchmarkPulse), benchmarkElapsed,
                  benchmarkEmulatedFrame,
                  benchmarkGuest.gameState,
                  benchmarkGuest.cursorValid
                      ? [NSString stringWithFormat:@"(%.2f,%.2f) state=%u",
                          benchmarkGuest.cursorX, benchmarkGuest.cursorY,
                          benchmarkGuest.cursorState]
                      : @"invalid", benchmarkGuest.cursorPointer,
                  benchmarkGuest.characterKinds[0], benchmarkGuest.slotTypes[0],
                  benchmarkGuest.characterKinds[1], benchmarkGuest.slotTypes[1],
                  benchmarkGuest.characterKinds[2], benchmarkGuest.slotTypes[2],
                  benchmarkGuest.characterKinds[3], benchmarkGuest.slotTypes[3]);
        lastBenchmarkPulse = benchmarkPulse;
    }
    BOOL modernCStick = _modernCStickHorizontal->load(std::memory_order_relaxed);
    std::string commands = MeleePadEncodePipeCommands(input, lastButtons, modernCStick);
    if (!commands.empty()) {
        uint16_t priorButtons = lastButtons;
        ssize_t written = ::write(_pipeFd, commands.data(), commands.size());
        if (written == static_cast<ssize_t>(commands.size())) {
            // Advance edge tracking only after the whole atomic FIFO message
            // is delivered; an EAGAIN will retry the same button transition.
            lastButtons = input.buttons;
            if (traceButtonEdges && priorButtons != input.buttons) {
                MeleePadLog(@"input button edge delivered previous=0x%04x current=0x%04x bytes=%lu",
                          priorButtons, input.buttons, (unsigned long)commands.size());
            }
        } else if (written < 0 && errno != EAGAIN) {
            MeleePadLog(@"input pipe write failed errno=%d bytes=%lu", errno,
                      (unsigned long)commands.size());
        } else if (written >= 0) {
            MeleePadLog(@"input pipe partial write bytes=%ld expected=%lu", (long)written,
                      (unsigned long)commands.size());
        }
    }
}

- (MeleePadBenchmarkGuestState)benchmarkGuestState {
    MeleePadBenchmarkGuestState result = {};
    // Revision-1.00 globals validated from the generated instructions. Read
    // the active P1 CSS cursor pointer instead of assuming one heap address;
    // different game modes allocate that same cursor at different locations.
    constexpr u32 kGameStateAddress = 0x80477D68u;
    constexpr u32 kCursorPointerAddress = 0x8049EA88u;
    constexpr u32 kCssDataPointerAddress = 0x804D4B30u;
    std::scoped_lock lock(*_runtimeMutex);
    if (_runtime == nullptr)
        return result;
    auto &memory = Core::System::GetInstance().GetMemory();
    if (!memory.IsInitialized())
        return result;
    const std::span<const u8> mem1{memory.GetRAM(), memory.GetRamSizeReal()};
    const std::span<const u8> mem2{memory.GetEXRAM(), memory.GetExRamSizeReal()};
    if (const auto gameState = MemoryWatcherUtils::ReadStaticRecompU32(
            mem1, mem2, kGameStateAddress))
        result.gameState = *gameState;
    const auto cursorPointer = MemoryWatcherUtils::ReadStaticRecompU32(
        mem1, mem2, kCursorPointerAddress);
    if (!cursorPointer)
        return result;
    result.cursorPointer = *cursorPointer;
    constexpr u32 kMem1Start = 0x80000000u;
    constexpr u32 kMem1End = 0x81800000u;
    if (*cursorPointer < kMem1Start || *cursorPointer > kMem1End - 0x14u)
        return result;
    const u32 cursorPositionAddress = *cursorPointer + 0x0Cu;
    const auto metadata = MemoryWatcherUtils::ReadStaticRecompU32(
        mem1, mem2, *cursorPointer + 4);
    const auto xBits = MemoryWatcherUtils::ReadStaticRecompU32(
        mem1, mem2, cursorPositionAddress);
    const auto yBits = MemoryWatcherUtils::ReadStaticRecompU32(
        mem1, mem2, cursorPositionAddress + 4);
    if (!metadata || !xBits || !yBits)
        return result;
    const float x = std::bit_cast<float>(*xBits);
    const float y = std::bit_cast<float>(*yBits);
    const unsigned state = (*metadata >> 16) & 0xFFu;
    if (!std::isfinite(x) || !std::isfinite(y) || std::abs(x) > 1000.0f ||
        std::abs(y) > 1000.0f || state > 3)
        return result;
    result.cursorValid = true;
    result.cursorX = x;
    result.cursorY = y;
    result.cursorState = static_cast<uint8_t>(state);
    const auto cssData = MemoryWatcherUtils::ReadStaticRecompU32(
        mem1, mem2, kCssDataPointerAddress);
    if (!cssData || *cssData < kMem1Start || *cssData > kMem1End - 0xF8u)
        return result;
    constexpr u32 kFirstPlayerOffset = 0x70u;
    constexpr u32 kPlayerStride = 0x24u;
    for (std::size_t player = 0; player < 4; ++player) {
        const auto playerWord = MemoryWatcherUtils::ReadStaticRecompU32(
            mem1, mem2, *cssData + kFirstPlayerOffset +
                            static_cast<u32>(player) * kPlayerStride);
        if (!playerWord)
            return result;
        result.characterKinds[player] = static_cast<uint8_t>(*playerWord >> 24);
        result.slotTypes[player] = static_cast<uint8_t>(*playerWord >> 16);
    }
    result.cssValid = true;
    return result;
}

- (BOOL)setBenchmarkRandomSeed:(u32)seed previousValue:(u32 *)previousValue {
    // The revision-1.00 DOL loads its HSD random-state pointer from r13-22292.
    // Validate the initialized pointer before making this benchmark-only RAM
    // write so a different game revision fails closed.
    constexpr u32 kRandomSeedAddress = 0x804D3E08u;
    constexpr u32 kRandomSeedPointerAddress = 0x804D3E0Cu;
    std::scoped_lock lock(*_runtimeMutex);
    if (_runtime == nullptr)
        return NO;
    auto &system = Core::System::GetInstance();
    Core::CPUThreadGuard cpuThreadGuard(system);
    auto &memory = system.GetMemory();
    if (!memory.IsInitialized() ||
        memory.Read_U32(kRandomSeedPointerAddress) != kRandomSeedAddress)
        return NO;
    if (previousValue != nullptr)
        *previousValue = memory.Read_U32(kRandomSeedAddress);
    memory.Write_U32(seed, kRandomSeedAddress);
    return YES;
}

- (BOOL)setBenchmarkForcedStage:(u8)stageId previousValue:(u8 *)previousValue {
    // Revision-1.00 stores mnStageSel's active SSSData pointer at r13-18960.
    // Callers additionally gate this write on Training mode's stage-select
    // scene. Validate the pointed-to structure before changing its one signed
    // force_stage_id byte; unexpected revisions and layouts fail closed.
    constexpr u32 kStageSelectDataPointerAddress = 0x804D4B10u;
    std::scoped_lock lock(*_runtimeMutex);
    if (_runtime == nullptr)
        return NO;
    auto &system = Core::System::GetInstance();
    Core::CPUThreadGuard cpuThreadGuard(system);
    auto &memory = system.GetMemory();
    if (!memory.IsInitialized())
        return NO;
    const u32 stageSelectData = memory.Read_U32(kStageSelectDataPointerAddress);
    if (memory.GetPointerForRange(stageSelectData, 5) == nullptr ||
        memory.Read_U8(stageSelectData + 1) != 0 ||
        memory.Read_U8(stageSelectData + 2) > 1 ||
        memory.Read_U8(stageSelectData + 3) != 0xFFu ||
        memory.Read_U8(stageSelectData + 4) != 0)
        return NO;
    if (previousValue != nullptr)
        *previousValue = memory.Read_U8(stageSelectData + 3);
    memory.Write_U8(stageId, stageSelectData + 3);
    return YES;
}

- (BOOL)setBenchmarkFourPlayerRosterPreviousValue:(u32 *)previousValue {
    // Revision-1.00 stores the active CSSData pointer at r13-18928. The route
    // opens every controller door through normal UI input first; this narrow,
    // benchmark-only write then removes random CPU-token overlap while leaving
    // the match rules, port kinds, levels, costumes, and saved data untouched.
    constexpr u32 kGameStateAddress = 0x80477D68u;
    constexpr u32 kCssDataPointerAddress = 0x804D4B30u;
    constexpr u32 kFirstPlayerOffset = 0x70u;
    constexpr u32 kPlayerStride = 0x24u;
    constexpr std::array<u8, 4> kRoster = {{0x10u, 0x04u, 0x05u, 0x06u}};
    constexpr std::array<u8, 4> kSlotTypes = {{0u, 1u, 1u, 1u}};
    std::scoped_lock lock(*_runtimeMutex);
    if (_runtime == nullptr)
        return NO;
    auto &system = Core::System::GetInstance();
    Core::CPUThreadGuard cpuThreadGuard(system);
    auto &memory = system.GetMemory();
    if (!memory.IsInitialized())
        return NO;
    const u32 gameState = memory.Read_U32(kGameStateAddress);
    if (((gameState >> 24) & 0xFFu) != 0x02u || (gameState & 0xFFu) != 0u)
        return NO;
    const u32 cssData = memory.Read_U32(kCssDataPointerAddress);
    if (memory.GetPointerForRange(cssData + kFirstPlayerOffset,
                                  kPlayerStride * 3u + 4u) == nullptr)
        return NO;
    u32 packedPrevious = 0;
    for (std::size_t player = 0; player < kRoster.size(); ++player) {
        const u32 playerAddress =
            cssData + kFirstPlayerOffset + static_cast<u32>(player) * kPlayerStride;
        const u32 playerWord = memory.Read_U32(playerAddress);
        if (static_cast<u8>(playerWord >> 16) != kSlotTypes[player])
            return NO;
        packedPrevious |= static_cast<u32>(playerWord >> 24) << (24u - player * 8u);
    }
    for (std::size_t player = 0; player < kRoster.size(); ++player) {
        const u32 playerAddress =
            cssData + kFirstPlayerOffset + static_cast<u32>(player) * kPlayerStride;
        memory.Write_U8(kRoster[player], playerAddress);
    }
    if (previousValue != nullptr)
        *previousValue = packedPrevious;
    return YES;
}

- (void)beginNetplayWithRole:(moderngekko::frontend::NetplayRole)role
                     address:(NSString *)address
                    nickname:(NSString *)nickname
                        port:(uint16_t)port
              usingTraversal:(BOOL)usingTraversal
             automaticBuffer:(BOOL)automaticBuffer
                bufferFrames:(NSUInteger)bufferFrames
                  completion:(void (^)(NSString *_Nullable))completion {
    _allowOfflineCheats->store(false, std::memory_order_release);
    [self stop];
    NSString *gameRoot = [_lastGameRoot copy];
    NSString *discImagePath = [_lastDiscImagePath copy];
    NSString *modulePath = [_lastModulePath copy];
    NSString *userDirectory = [_lastUserDirectory copy];
    dispatch_async(_netplayQueue, ^{
        if (*self->_netplaySession) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@"An Online Play session is already active.");
            });
            return;
        }

        NSString *runtimeUserDirectory = MeleePadRuntimeUserDirectory(userDirectory);
        NSError *cheatConfigError = nil;
        MeleePadConfigureOfflineCheats(runtimeUserDirectory, NO, &cheatConfigError);
        if (cheatConfigError != nil)
            MeleePadLog(@"netplay cheat cleanup failed: %@",
                      cheatConfigError.localizedDescription);
        UICommon::SetUserDirectory(runtimeUserDirectory.fileSystemRepresentation);
        UICommon::Init();
        moderngekko::detail::SetExternalUICommon(true);
        *self->_netplayServicesActive = YES;

        Config::SetBase(Config::MAIN_CPU_THREAD, true);
        Config::SetBase(Config::MAIN_CPU_CORE, PowerPC::CPUCore::StaticRecomp);
        Config::SetBase(Config::MAIN_ENABLE_CHEATS, false);
        Config::SetBase(Config::NETPLAY_SAVEDATA_LOAD, true);
        Config::SetBase(Config::NETPLAY_SAVEDATA_WRITE, false);
        Config::SetBase(Config::NETPLAY_SAVEDATA_SYNC_ALL_WII, false);
        Config::SetBase(Config::NETPLAY_SYNC_CODES, false);
        Config::SetBase(Config::NETPLAY_STRICT_SETTINGS_SYNC, true);
        Config::SetBase(Config::NETPLAY_NETWORK_MODE, std::string("fixeddelay"));
        Config::SetBase(Config::NETPLAY_USE_INDEX, false);

        moderngekko::RuntimeConfig config;
        config.game_root = gameRoot.fileSystemRepresentation;
        // Netplay selects and fingerprints sys/main.dol. Keep the session and
        // synchronized runtime on that file instead of an imported ISO.
        config.user_directory = runtimeUserDirectory.fileSystemRepresentation;
        config.graphics.backend = "Metal";
        config.headless = false;
        config.show_fps_in_title = false;
        config.enable_gmse01_60fps = false;
        config.render_surface = (__bridge void *)self->_layer;
        config.log_callback = MeleePadRuntimeLogCallback;
        config.module = moderngekko::ModuleSource::DynamicPath(
            modulePath.fileSystemRepresentation);

        moderngekko::frontend::NetplayOptions options;
        options.role = role;
        options.use_traversal = usingTraversal;
        options.address = address.UTF8String ?: "";
        options.port = port;
        options.nickname = nickname.UTF8String ?: "Player";
        options.buffer = automaticBuffer ? "auto" : std::to_string(
            std::clamp<NSUInteger>(bufferFrames, 1, 20));
        options.controllers = {"Pipe/0/meleepad"};

        moderngekko::frontend::NetplayExitCode failure =
            moderngekko::frontend::NetplayExitCode::Failed;
        *self->_netplaySession = moderngekko::frontend::NetplaySession::Create(
            std::move(config), std::move(options), &failure);
        NSString *error = nil;
        if (!*self->_netplaySession) {
            error = MeleePadNetplayFailureMessage(failure);
            moderngekko::detail::SetExternalUICommon(false);
            UICommon::Shutdown();
            *self->_netplayServicesActive = NO;
        }
        MeleePadLog(@"netplay session create role=%@ result=%@",
                  role == moderngekko::frontend::NetplayRole::Host ? @"host" : @"join",
                  error ?: @"connected");
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    });
}

- (void)beginNetplayHostingWithNickname:(NSString *)nickname
                                   port:(uint16_t)port
                         usingTraversal:(BOOL)usingTraversal
                        automaticBuffer:(BOOL)automaticBuffer
                           bufferFrames:(NSUInteger)bufferFrames
                             completion:(void (^)(NSString *_Nullable))completion {
    [self beginNetplayWithRole:moderngekko::frontend::NetplayRole::Host
                       address:@"127.0.0.1" nickname:nickname port:port
                usingTraversal:usingTraversal
               automaticBuffer:automaticBuffer bufferFrames:bufferFrames
                    completion:completion];
}

- (void)beginNetplayJoiningAddress:(NSString *)address
                          nickname:(NSString *)nickname
                              port:(uint16_t)port
                    usingTraversal:(BOOL)usingTraversal
                   automaticBuffer:(BOOL)automaticBuffer
                      bufferFrames:(NSUInteger)bufferFrames
                        completion:(void (^)(NSString *_Nullable))completion {
    [self beginNetplayWithRole:moderngekko::frontend::NetplayRole::Join
                       address:address nickname:nickname port:port
                usingTraversal:usingTraversal
               automaticBuffer:automaticBuffer bufferFrames:bufferFrames
                    completion:completion];
}

- (void)pollNetplayWithCompletion:(void (^)(NSDictionary<NSString *,id> *))completion {
    dispatch_async(_netplayQueue, ^{
        if (!*self->_netplaySession) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(@{@"state": @"idle"}); });
            return;
        }
        moderngekko::frontend::NetplayLobbySnapshot snapshot =
            (*self->_netplaySession)->Snapshot();
        NSMutableArray<NSDictionary<NSString *, id> *> *players = [NSMutableArray array];
        for (const moderngekko::frontend::NetplayPlayerSnapshot &player : snapshot.players) {
            NSMutableArray<NSString *> *slots = [NSMutableArray array];
            for (std::uint8_t slot : player.controller_slots)
                [slots addObject:[NSString stringWithFormat:@"GC %u", slot + 1]];
            [players addObject:@{
                @"name": @(player.name.c_str()),
                @"ping": @(player.ping_ms),
                @"controller": slots.count > 0 ? [slots componentsJoinedByString:@", "] : @"No controller",
                @"compatible": @(player.game_matches),
                @"ready": @(player.ready),
                @"local": @(player.local),
            }];
        }
        NSMutableArray<NSDictionary<NSString *, id> *> *messages = [NSMutableArray array];
        for (const moderngekko::frontend::NetplayChatMessageSnapshot &message :
             snapshot.chat_messages) {
            NSString *sender = [[NSString alloc]
                initWithBytes:message.sender.data()
                       length:message.sender.size()
                     encoding:NSUTF8StringEncoding] ?: @"Player";
            NSString *text = [[NSString alloc]
                initWithBytes:message.text.data()
                       length:message.text.size()
                     encoding:NSUTF8StringEncoding] ?: @"Message could not be displayed.";
            [messages addObject:@{
                @"id": @(message.id),
                @"sender": sender,
                @"text": text,
                @"local": @(message.local),
                @"transport": @"peer",
            }];
        }
        NSString *state = @"lobby";
        if (snapshot.state == moderngekko::frontend::NetplayState::Starting)
            state = @"starting";
        else if (snapshot.state == moderngekko::frontend::NetplayState::Running)
            state = @"running";
        else if (snapshot.state == moderngekko::frontend::NetplayState::Failed)
            state = @"failed";
        NSDictionary *result = @{
            @"state": state,
            @"role": snapshot.role == moderngekko::frontend::NetplayRole::Host ? @"host" : @"join",
            @"players": players,
            @"messages": messages,
            @"buffer": @(snapshot.buffer_frames),
            @"automaticBuffer": @(snapshot.adaptive_buffer),
            @"canStart": @(snapshot.can_start),
            @"roomCode": snapshot.room_code.empty() ? @"" : @(snapshot.room_code.c_str()),
            @"status": snapshot.status.empty() ? @"" : @(snapshot.status.c_str()),
            @"error": snapshot.error.empty() ? @"" : @(snapshot.error.c_str()),
            @"connectionLost": @(snapshot.connection_lost),
        };

        if (!*self->_netplayBootInstalled) {
            std::unique_ptr<BootSessionData> boot = (*self->_netplaySession)->TakeBootData();
            if (boot) {
                moderngekko::detail::SetBootSessionData(std::move(boot));
                *self->_netplayBootInstalled = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self startWithGameRoot:self->_lastGameRoot
                             discImagePath:@""
                                modulePath:self->_lastModulePath
                             userDirectory:self->_lastUserDirectory
                                   onError:self->_onError ?: ^(NSString *message) {
                        MeleePadLog(@"netplay runtime error: %@", message);
                    }];
                    if (self.onNetplayMatchStarted)
                        self.onNetplayMatchStarted();
                });
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(result); });
    });
}

- (void)setNetplayReady:(BOOL)ready {
    dispatch_async(_netplayQueue, ^{
        if (*self->_netplaySession)
            (*self->_netplaySession)->SetReady(ready);
    });
}

- (void)sendNetplayChatMessage:(NSString *)message
                    completion:(void (^)(NSString *_Nullable error))completion {
    NSString *copy = [message copy] ?: @"";
    dispatch_async(_netplayQueue, ^{
        const char *utf8 = copy.UTF8String;
        BOOL sent = *self->_netplaySession && utf8 != nullptr &&
            (*self->_netplaySession)->SendChatMessage(utf8);
        MeleePadLog(@"netplay peer chat send result=%@ characters=%lu",
                  sent ? @"sent" : @"rejected", (unsigned long)copy.length);
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(sent ? nil : @"The message could not be sent. Check that the room is still connected.");
        });
    });
}

- (void)requestNetplayStart {
    dispatch_async(_netplayQueue, ^{
        if (*self->_netplaySession)
            (*self->_netplaySession)->RequestStart();
    });
}

- (void)endNetplayWithCompletion:(dispatch_block_t)completion {
    [self stop];
    dispatch_async(_netplayQueue, ^{
        if (*self->_netplaySession) {
            (*self->_netplaySession)->Stop();
            self->_netplaySession->reset();
        }
        *self->_netplayBootInstalled = NO;
        self.onNetplayMatchStarted = nil;
        self.onNetplayMatchEnded = nil;
        if (*self->_netplayServicesActive) {
            moderngekko::detail::SetExternalUICommon(false);
            UICommon::Shutdown();
            *self->_netplayServicesActive = NO;
        }
        self->_allowOfflineCheats->store(true, std::memory_order_release);
        dispatch_async(dispatch_get_main_queue(), completion ?: ^{});
    });
}

- (void)setRenderScale:(NSInteger)scale {
    NSInteger clamped = scale < 1 ? 1 : (scale > 4 ? 4 : scale);
    if (!_running->load())
        return; // Runtime not booted yet; the scale applies at boot.
    // Config::SetCurrent is mutex-protected and the video backend refreshes
    // g_ActiveConfig on the next config callback.
    Config::SetCurrent(Config::GFX_EFB_SCALE, static_cast<int>(clamped));
    MeleePadLog(@"runtime render scale=%ld source=live", (long)clamped);
}

- (void)applyAspectRatioMode:(MeleePadAspectRatioMode)mode source:(NSString *)source {
    NSString *modeName = @"original-4:3";
    switch (mode) {
    case MeleePadAspectRatioWidescreen:
        modeName = @"widescreen-16:9";
        Config::SetCurrent(Config::GFX_ASPECT_RATIO, AspectMode::ForceWide);
        Config::SetCurrent(Config::GFX_WIDESCREEN_HACK, true);
        break;
    case MeleePadAspectRatioFillScreen: {
        modeName = @"fill-screen";
        CGSize size = _layer.drawableSize;
        int width = MAX(1, (int)std::lround(size.width));
        int height = MAX(1, (int)std::lround(size.height));
        Config::SetCurrent(Config::GFX_CUSTOM_ASPECT_RATIO_WIDTH, width);
        Config::SetCurrent(Config::GFX_CUSTOM_ASPECT_RATIO_HEIGHT, height);
        Config::SetCurrent(Config::GFX_ASPECT_RATIO, AspectMode::CustomStretch);
        Config::SetCurrent(Config::GFX_WIDESCREEN_HACK, true);
        break;
    }
    case MeleePadAspectRatioOriginal:
    default:
        Config::SetCurrent(Config::GFX_ASPECT_RATIO, AspectMode::ForceStandard);
        Config::SetCurrent(Config::GFX_WIDESCREEN_HACK, false);
        break;
    }
    MeleePadLog(@"runtime aspect mode=%@ source=%@", modeName, source);
}

- (void)setAspectRatioMode:(MeleePadAspectRatioMode)mode {
    if (!_running->load())
        return; // Runtime not booted yet; the mode applies at boot.
    [self applyAspectRatioMode:mode source:@"live"];
}

- (void)setModernCStickHorizontal:(BOOL)enabled {
    _modernCStickHorizontal->store(enabled, std::memory_order_relaxed);
}

- (double)currentFPS {
    if (!_running->load())
        return 0.0;
    return Core::System::GetInstance().GetPerfMetrics().GetFPS();
}

- (double)currentSpeed {
    if (!_running->load())
        return 0.0;
    return Core::System::GetInstance().GetPerfMetrics().GetSpeed();
}

- (double)currentVPS {
    if (!_running->load())
        return 0.0;
    return Core::System::GetInstance().GetPerfMetrics().GetVPS();
}

- (BOOL)isGameplayScene {
    if (!_running->load())
        return NO;

    // GALE01 revision 0's verified GameState address. Do not use the public
    // revision-1.02 gm_804D6720 scene pointer here: it addresses unrelated
    // memory in the supported revision-1.00 image.
    constexpr u32 kGameStateAddress = 0x80477D68u;
    std::scoped_lock lock(*_runtimeMutex);
    if (_runtime == nullptr)
        return NO;

    auto &memory = Core::System::GetInstance().GetMemory();
    if (!memory.IsInitialized())
        return NO;
    const std::span<const u8> mem1{memory.GetRAM(), memory.GetRamSizeReal()};
    const std::span<const u8> mem2{memory.GetEXRAM(), memory.GetExRamSizeReal()};
    const auto gameState =
        MemoryWatcherUtils::ReadStaticRecompU32(mem1, mem2, kGameStateAddress);
    if (!gameState)
        return NO;
    return MeleePadShouldApplyRightStickSmashForRevision0GameState(*gameState);
}

- (NSString *)currentPerformanceProfile {
    @synchronized (self) {
        return _activePerformanceProfile ?: @"unknown";
    }
}

- (NSString *)efbResolution {
    if (!_running->load())
        return @"";
    auto &metrics = Core::System::GetInstance().GetPerfMetrics();
    return [NSString stringWithFormat:@"%ux%u", metrics.GetEFBWidth(),
                                      metrics.GetEFBHeight()];
}

- (NSString *)diagnosticSummary {
    moderngekko::RuntimeDiagnosticsSnapshot diagnostics = {};
    BOOL hasRuntime = NO;
    {
        std::scoped_lock lock(*_runtimeMutex);
        hasRuntime = _runtime != nullptr;
        if (hasRuntime)
            diagnostics = _runtime->GetDiagnosticsSnapshot();
    }
    NSString *profile;
    NSString *profileSource;
    NSString *frameMode;
    unsigned long long audioCallbacks = 0;
    unsigned long long audioFrames = 0;
    unsigned long long audioDMAUnderruns = 0;
    unsigned long long audioDMAQueued = 0;
    unsigned long long audioDMATarget = 0;
    if (SoundStream *soundStream = Core::System::GetInstance().GetSoundStream()) {
        if (Mixer *mixer = soundStream->GetMixer()) {
            audioCallbacks = mixer->GetOutputCallbackCount();
            audioFrames = mixer->GetOutputFrameCount();
            audioDMAUnderruns = mixer->GetDMAUnderrunCount();
            audioDMAQueued = mixer->GetDMAQueuedGranules();
            audioDMATarget = mixer->GetDMAQueueTargetGranules();
        }
    }
    @synchronized (self) {
        profile = _activePerformanceProfile;
        profileSource = _activePerformanceSource;
        frameMode = _activeFrameMode;
    }
    return [NSString stringWithFormat:
        @"runtimeState=%@ paused=%d audioInterrupted=%d\n"
         @"audio callbacks=%llu frames=%llu dmaUnderruns=%llu dmaQueued=%llu dmaTarget=%llu\n"
         @"performanceProfile=%@ profileSource=%@ frameMode=%@\n"
         @"metalDevice=%@ moduleBytes=%llu\n"
         @"graphics frames=%llu projectionHash=%016llx draws=%u primitives=%u "
         @"bpLoads=%u cpLoads=%u xfLoads=%u shaderChanges=%u scissors=%u\n"
         @"graphicsResources texturesCreated=%u texturesAlive=%u "
         @"vertexShadersCreated=%u pixelShadersCreated=%u\n",
        hasRuntime ? @"created" : (_starting->load() ? @"starting" :
            (_running->load() ? @"running-without-handle" : @"stopped")),
        _runtimePausedForSystemEvent, _audioInterrupted,
        audioCallbacks, audioFrames, audioDMAUnderruns, audioDMAQueued, audioDMATarget,
        profile ?: @"unknown", profileSource ?: @"unknown", frameMode ?: @"unknown",
        _layer.device.name ?: @"unknown", _moduleFileSize,
        diagnostics.frame_count, diagnostics.projection_hash,
        diagnostics.draw_calls, diagnostics.primitives,
        diagnostics.bp_loads, diagnostics.cp_loads, diagnostics.xf_loads,
        diagnostics.shader_changes, diagnostics.scissor_count,
        diagnostics.textures_created, diagnostics.textures_alive,
        diagnostics.vertex_shaders_created, diagnostics.pixel_shaders_created];
}

- (void)stop {
    MeleePadLog(@"runtime stop requested starting=%d running=%d",
              _starting->load(), _running->load());
    *_stopRequested = true;
    {
        std::scoped_lock lock(*_runtimeMutex);
        if (_runtime != nullptr)
            _runtime->RequestStop();
    }
    if (_gameThread->joinable())
        _gameThread->join();
    *_starting = false;
    *_running = false;
    _runtimePausedForSystemEvent = NO;
}

- (void)pauseRuntimeForSystemEvent {
    _applicationActive = NO;
    _systemStateRetryAttempts = 0;
    [self applySystemPauseState];
}

- (void)resumeRuntimeAfterSystemEvent {
    _applicationActive = YES;
    if (_audioInterrupted) {
        // iOS can omit the interruption-ended notification after system UI
        // such as screenshot capture. Foreground activation is our recovery
        // boundary; setActive below remains the authority and will retry if a
        // real interruption still owns the audio session.
        _audioInterrupted = NO;
        MeleePadLog(@"audio interruption latch cleared on foreground activation");
    }
    _systemStateRetryAttempts = 0;
    [self applySystemPauseState];
}

- (void)applySystemPauseState {
    BOOL shouldPause = !_applicationActive || _audioInterrupted;
    if (shouldPause) {
        _audioSessionNeedsReactivation = YES;
        if (!_audioSessionDeactivatedForSystemEvent) {
            NSError *audioError = nil;
            [AVAudioSession.sharedInstance
                setActive:NO
               withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                     error:&audioError];
            if (audioError) {
                MeleePadLog(@"audio session deactivation failed: %@", audioError);
            } else {
                _audioSessionDeactivatedForSystemEvent = YES;
            }
        }

        if (_runtimePausedForSystemEvent)
            return;

        std::optional<moderngekko::RuntimeError> pauseError;
        BOOL hadRuntime = NO;
        BOOL corePaused = NO;
        {
            std::scoped_lock lock(*_runtimeMutex);
            hadRuntime = _runtime != nullptr;
            if (hadRuntime) {
                pauseError = _runtime->Pause();
                corePaused = !pauseError &&
                    Core::GetState(Core::System::GetInstance()) == Core::State::Paused;
            }
        }
        if (hadRuntime && corePaused) {
            _runtimePausedForSystemEvent = YES;
            _systemStateRetryAttempts = 0;
            MeleePadLog(@"runtime paused for system event");
        } else {
            if (_systemStateRetryAttempts == 0 && pauseError)
                MeleePadLog(@"runtime pause pending: %s", pauseError->message.c_str());
            else if (_systemStateRetryAttempts == 0 && hadRuntime)
                MeleePadLog(@"runtime pause pending: core not yet pausable");
            else if (_systemStateRetryAttempts == 0)
                MeleePadLog(@"runtime pause pending: runtime not created");
            if (hadRuntime || _starting->load())
                [self scheduleSystemStateRetry];
        }
        return;
    }

    if (_audioSessionNeedsReactivation) {
        NSError *audioError = nil;
        [AVAudioSession.sharedInstance setActive:YES error:&audioError];
        if (audioError) {
            if (_systemStateRetryAttempts == 0)
                MeleePadLog(@"audio session reactivation pending: %@", audioError);
            [self scheduleSystemStateRetry];
            return;
        }
        _audioSessionNeedsReactivation = NO;
        _audioSessionDeactivatedForSystemEvent = NO;
        _systemStateRetryAttempts = 0;
        MeleePadLog(@"audio session reactivated route=%@",
                  AVAudioSession.sharedInstance.currentRoute.outputs.firstObject.portType ?: @"none");
    }

    if (!_runtimePausedForSystemEvent)
        return;

    std::optional<moderngekko::RuntimeError> resumeError;
    BOOL hadRuntime = NO;
    {
        std::scoped_lock lock(*_runtimeMutex);
        hadRuntime = _runtime != nullptr;
        if (hadRuntime)
            resumeError = _runtime->Resume();
    }
    if (hadRuntime && !resumeError) {
        _runtimePausedForSystemEvent = NO;
        _systemStateRetryAttempts = 0;
        MeleePadLog(@"runtime resumed after system event");
    } else {
        if (_systemStateRetryAttempts == 0 && resumeError)
            MeleePadLog(@"runtime resume pending: %s", resumeError->message.c_str());
        if (hadRuntime || _starting->load())
            [self scheduleSystemStateRetry];
    }
}

- (void)scheduleSystemStateRetry {
    static const NSUInteger kMaxSystemStateRetryAttempts = 20;
    if (_systemStateRetryScheduled ||
        _systemStateRetryAttempts >= kMaxSystemStateRetryAttempts)
        return;
    _systemStateRetryScheduled = YES;
    ++_systemStateRetryAttempts;
    __weak MeleePadCoreHost *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC),
                   dispatch_get_main_queue(), ^{
        MeleePadCoreHost *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        strongSelf->_systemStateRetryScheduled = NO;
        [strongSelf applySystemPauseState];
    });
}

- (void)handleAudioSessionInterruption:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type =
        (AVAudioSessionInterruptionType)[info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        MeleePadLog(@"audio interruption began");
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_audioInterrupted = YES;
            self->_systemStateRetryAttempts = 0;
            [self applySystemPauseState];
        });
        return;
    }

    AVAudioSessionInterruptionOptions options =
        (AVAudioSessionInterruptionOptions)[info[AVAudioSessionInterruptionOptionKey]
            unsignedIntegerValue];
    BOOL shouldResume = (options & AVAudioSessionInterruptionOptionShouldResume) != 0;
    MeleePadLog(@"audio interruption ended shouldResume=%d", shouldResume);
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_audioInterrupted = NO;
        self->_systemStateRetryAttempts = 0;
        [self applySystemPauseState];
    });
}

- (void)restartWithGameRoot:(NSString *)gameRoot
              discImagePath:(NSString *)discImagePath
                 modulePath:(NSString *)modulePath {
    if (_gameThread->joinable()) {
        [self stop];
    }
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *userDirectory = [paths.firstObject stringByAppendingPathComponent:@"MeleePad"];
    [[NSFileManager defaultManager] createDirectoryAtPath:userDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    __weak MeleePadCoreHost *weakSelf = self;
    [self startWithGameRoot:gameRoot
              discImagePath:discImagePath
                 modulePath:modulePath
              userDirectory:userDirectory
                    onError:^(NSString *message) {
        (void)weakSelf;
        NSLog(@"[MeleePad] runtime error after restart: %@", message);
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_gameThread->joinable())
        [self stop];
    if (_pipeFd >= 0)
        ::close(_pipeFd);
    if (*_netplaySession || *_netplayServicesActive) {
        dispatch_sync(_netplayQueue, ^{
            if (*self->_netplaySession) {
                (*self->_netplaySession)->Stop();
                self->_netplaySession->reset();
            }
            if (*self->_netplayServicesActive) {
                moderngekko::detail::SetExternalUICommon(false);
                UICommon::Shutdown();
            }
        });
    }
    delete _gameThread;
    delete _stopRequested;
    delete _starting;
    delete _running;
    delete _modernCStickHorizontal;
    delete _allowOfflineCheats;
    delete _runtimeMutex;
    delete _netplaySession;
    delete _netplayServicesActive;
    delete _netplayBootInstalled;
}

@end
