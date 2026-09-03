#import "SsbmPadCoreHost.h"
#import "SsbmPadControllerMapping.h"
#import "SsbmPadDiagnostics.h"
#import "SsbmPadInputPipeEncoder.h"

#import <AVFAudio/AVFAudio.h>
#import <Metal/Metal.h>
#import <fcntl.h>
#import <pthread.h>
#import <sys/stat.h>
#import <sys/un.h>

#include <atomic>
#include <algorithm>
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
#include "Core/Boot/Boot.h"
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

static void SsbmPadRuntimeLogCallback(
    moderngekko::RuntimeLogLevel level, const char *category,
    const char *message, void *userData) {
    (void)userData;
    @autoreleasepool {
        SsbmPadLogRuntimeEvent(
            level == moderngekko::RuntimeLogLevel::Error ? @"error" : @"warning",
            category != nullptr ? @(category) : @"runtime",
            message != nullptr ? @(message) : @"unknown runtime event");
    }
}

static NSString *SsbmPadRuntimeUserDirectory(NSString *userDirectory) {
#if TARGET_OS_SIMULATOR
    NSString *override =
        NSProcessInfo.processInfo.environment[@"SSBMPAD_RUNTIME_USER_DIRECTORY"];
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
        SsbmPadLog(@"runtime user-directory override enabled source=simulator-diagnostic");
        return override;
    }

    SsbmPadLog(@"runtime user-directory override rejected sameDirectory=%d socketFits=%d",
              sameDirectory, socketFits);
#endif
    return userDirectory;
}

static NSString *SsbmPadNetplayFailureMessage(moderngekko::frontend::NetplayExitCode failure) {
    using moderngekko::frontend::NetplayExitCode;
    switch (failure) {
    case NetplayExitCode::InvalidConfiguration:
        return @"The selected game data or controller configuration is invalid.";
    case NetplayExitCode::HostUnavailable:
        return @"The host could not be reached. Check the address, port, and network.";
    case NetplayExitCode::VersionMismatch:
        return @"The other player is using a different SsbmPad netplay version.";
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

@interface SsbmPadCoreHost ()
- (void)applyAspectRatioMode:(SsbmPadAspectRatioMode)mode source:(NSString *)source;
- (void)applySystemPauseState;
- (void)scheduleSystemStateRetry;
- (void)handleAudioSessionInterruption:(NSNotification *)notification;
@end

@implementation SsbmPadCoreHost {
    CAMetalLayer *_layer;
    std::thread *_gameThread;
    std::atomic<bool> *_stopRequested;
    std::atomic<bool> *_starting;
    std::atomic<bool> *_running;
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
        _netplayQueue = dispatch_queue_create("com.ssbmpad.netplay-session", DISPATCH_QUEUE_SERIAL);
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
        SsbmPadLog(@"audio session setup failed: %@", audioSessionError);
    else
        SsbmPadLog(@"audio session active route=%@", audioSession.currentRoute.outputs.firstObject.portType ?: @"none");

    NSString *pipeDir = [userDirectory stringByAppendingPathComponent:@"Pipes"];
    NSString *pipePath = [pipeDir stringByAppendingPathComponent:@"ssbmpad"];
    [[NSFileManager defaultManager] createDirectoryAtPath:pipeDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    // The runtime opens the FIFO read-only; recreate if a stale file exists.
    ::unlink(pipePath.fileSystemRepresentation);
    int fifoResult = ::mkfifo(pipePath.fileSystemRepresentation, 0666);
    SsbmPadLog(@"input pipe create result=%d errno=%d", fifoResult, fifoResult == 0 ? 0 : errno);

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
         "Device = Pipe/0/ssbmpad\n"
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

    SsbmPadLog(@"runtime thread starting discImage=%d moduleExists=%d",
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
        NSString *runtimeUserDirectory = SsbmPadRuntimeUserDirectory(userDirectory);
        moderngekko::RuntimeConfig config;
        config.game_root = gameRoot.fileSystemRepresentation;
        if (discImagePath.length > 0)
            config.disc_image = discImagePath.fileSystemRepresentation;
        config.user_directory = runtimeUserDirectory.fileSystemRepresentation;
        config.graphics.backend = "Metal";
        config.headless = false;
        config.show_fps_in_title = false;
        config.log_callback = SsbmPadRuntimeLogCallback;
        // Melee is natively a 60 FPS title. The GMSE01-only Sunshine frame
        // patch must never be exposed or enabled by SsbmPad.
        config.enable_gmse01_60fps = false;
        NSArray<NSString *> *arguments = NSProcessInfo.processInfo.arguments;
        BOOL launchArgumentPerformance90 = [arguments
            containsObject:@"-ssbmpadExperimentalPerformanceMode"];
        BOOL launchArgumentPerformance95 = [arguments
            containsObject:@"-ssbmpadExperimentalPerformance95"];
        BOOL launchArgumentPerformanceQoSOnly = [arguments
            containsObject:@"-ssbmpadExperimentalPerformanceQoSOnly"];
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
            SsbmPadLog(@"runtime performance profile=%@ cpuVideoSplit=1 syncGPU=1 syncGPUMaxDistance=1000000 shaderCompilerThreads=3 emulatedCPUClock=%.2f gameThreadQoS=userInitiated qosResult=%d source=%@",
                      performanceProfile, emulatedCPUClock, qosResult, performanceSource);
        } else {
            SsbmPadLog(@"runtime performance profile=stable cpuVideoSplit=1 syncGPU=1 syncGPUMaxDistance=1000000 shaderCompilerThreads=3 emulatedCPUClock=1.00 gameThreadQoS=inherited source=default");
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
        SsbmPadLog(@"runtime frame mode=native 60 FPS source=GALE01");

        auto created = moderngekko::Runtime::Create(std::move(config));
        if (!created) {
            errorMessage = created.error->message;
            *_starting = false;
            SsbmPadLog(@"runtime create failed: %s", errorMessage.c_str());
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
        // Melee's raw-controller queue also waits for a periodic alarm. The
        // return address guard prevents other callers of the shared service
        // routine from being treated as idle.
        Config::SetBase(Config::MAIN_STATICRECOMP_CALLER_IDLE_PC, 0x80019550u);
        Config::SetBase(Config::MAIN_STATICRECOMP_CALLER_IDLE_LR, 0x801A4064u);
        SsbmPadLog(@"runtime scheduler idle skip=enabled pc=80348814 caller=80019550/801A4064");
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
        SsbmPadLog(@"runtime created");
        moderngekko::Runtime *createdRuntime = created.runtime.get();
        dispatch_sync(_netplayQueue, ^{
            if (*self->_netplaySession)
                (*self->_netplaySession)->AttachRuntime(createdRuntime);
        });

        // Apply the persisted render-resolution choice now that the runtime's
        // config layers exist.
        NSNumber *savedScaleValue =
            [[NSUserDefaults standardUserDefaults] objectForKey:@"SsbmPadRenderScale"];
        NSInteger savedScale = savedScaleValue ? savedScaleValue.integerValue : 1;
        NSInteger clampedSavedScale = savedScale < 1 ? 1 : (savedScale > 4 ? 4 : savedScale);
        Config::SetCurrent(Config::GFX_EFB_SCALE, static_cast<int>(clampedSavedScale));
        Config::SetCurrent(Config::GFX_MAX_EFB_SCALE, 12);
        SsbmPadLog(@"runtime render scale=%ld source=persisted", (long)clampedSavedScale);

        NSNumber *savedAspectValue = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"SsbmPadAspectRatioMode"];
        SsbmPadAspectRatioMode savedAspect = savedAspectValue ?
            (SsbmPadAspectRatioMode)savedAspectValue.integerValue : SsbmPadAspectRatioOriginal;
        [self applyAspectRatioMode:savedAspect source:@"persisted"];

        // Open the input FIFO for writing (blocks until the runtime reads it).
        NSString *pipePath = [[userDirectory stringByAppendingPathComponent:@"Pipes"]
            stringByAppendingPathComponent:@"ssbmpad"];
        for (int attempt = 0; attempt < 600 && !_stopRequested->load(); ++attempt) {
            _pipeFd = ::open(pipePath.fileSystemRepresentation, O_WRONLY | O_NONBLOCK);
            if (_pipeFd >= 0) {
                SsbmPadLog(@"input pipe connected attempt=%d", attempt + 1);
                break;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        if (_pipeFd < 0)
            SsbmPadLog(@"input pipe unavailable after wait errno=%d stopRequested=%d", errno,
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
        SsbmPadLog(@"runtime exited error=%d stopRequested=%d",
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

- (void)publishInput:(SsbmPadInputState)input {
    if (_pipeFd < 0)
        return;
    static uint16_t lastButtons = 0;
    static BOOL traceButtonEdges = [] {
        NSString *value = NSProcessInfo.processInfo.environment[@"SSBMPAD_TRACE_BUTTON_EDGES"];
        return value.boolValue;
    }();
    BOOL modernCStick = [SsbmPadSettings sharedSettings].modernCStickHorizontal;
    std::string commands = SsbmPadEncodePipeCommands(input, lastButtons, modernCStick);
    if (!commands.empty()) {
        uint16_t priorButtons = lastButtons;
        ssize_t written = ::write(_pipeFd, commands.data(), commands.size());
        if (written == static_cast<ssize_t>(commands.size())) {
            // Advance edge tracking only after the whole atomic FIFO message
            // is delivered; an EAGAIN will retry the same button transition.
            lastButtons = input.buttons;
            if (traceButtonEdges && priorButtons != input.buttons) {
                SsbmPadLog(@"input button edge delivered previous=0x%04x current=0x%04x bytes=%lu",
                          priorButtons, input.buttons, (unsigned long)commands.size());
            }
        } else if (written < 0 && errno != EAGAIN) {
            SsbmPadLog(@"input pipe write failed errno=%d bytes=%lu", errno,
                      (unsigned long)commands.size());
        } else if (written >= 0) {
            SsbmPadLog(@"input pipe partial write bytes=%ld expected=%lu", (long)written,
                      (unsigned long)commands.size());
        }
    }
}

- (void)beginNetplayWithRole:(moderngekko::frontend::NetplayRole)role
                     address:(NSString *)address
                    nickname:(NSString *)nickname
                        port:(uint16_t)port
             automaticBuffer:(BOOL)automaticBuffer
                bufferFrames:(NSUInteger)bufferFrames
                  completion:(void (^)(NSString *_Nullable))completion {
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

        NSString *runtimeUserDirectory = SsbmPadRuntimeUserDirectory(userDirectory);
        UICommon::SetUserDirectory(runtimeUserDirectory.fileSystemRepresentation);
        UICommon::Init();
        moderngekko::detail::SetExternalUICommon(true);
        *self->_netplayServicesActive = YES;

        Config::SetBase(Config::MAIN_CPU_THREAD, true);
        Config::SetBase(Config::MAIN_CPU_CORE, PowerPC::CPUCore::StaticRecomp);
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
        config.log_callback = SsbmPadRuntimeLogCallback;
        config.module = moderngekko::ModuleSource::DynamicPath(
            modulePath.fileSystemRepresentation);

        moderngekko::frontend::NetplayOptions options;
        options.role = role;
        options.address = address.UTF8String ?: "";
        options.port = port;
        options.nickname = nickname.UTF8String ?: "Player";
        options.buffer = automaticBuffer ? "auto" : std::to_string(
            std::clamp<NSUInteger>(bufferFrames, 1, 20));
        options.controllers = {"Pipe/0/ssbmpad"};

        moderngekko::frontend::NetplayExitCode failure =
            moderngekko::frontend::NetplayExitCode::Failed;
        *self->_netplaySession = moderngekko::frontend::NetplaySession::Create(
            std::move(config), std::move(options), &failure);
        NSString *error = nil;
        if (!*self->_netplaySession) {
            error = SsbmPadNetplayFailureMessage(failure);
            moderngekko::detail::SetExternalUICommon(false);
            UICommon::Shutdown();
            *self->_netplayServicesActive = NO;
        }
        SsbmPadLog(@"netplay session create role=%@ result=%@",
                  role == moderngekko::frontend::NetplayRole::Host ? @"host" : @"join",
                  error ?: @"connected");
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    });
}

- (void)beginNetplayHostingWithNickname:(NSString *)nickname
                                   port:(uint16_t)port
                        automaticBuffer:(BOOL)automaticBuffer
                           bufferFrames:(NSUInteger)bufferFrames
                             completion:(void (^)(NSString *_Nullable))completion {
    [self beginNetplayWithRole:moderngekko::frontend::NetplayRole::Host
                       address:@"127.0.0.1" nickname:nickname port:port
               automaticBuffer:automaticBuffer bufferFrames:bufferFrames
                    completion:completion];
}

- (void)beginNetplayJoiningAddress:(NSString *)address
                          nickname:(NSString *)nickname
                              port:(uint16_t)port
                   automaticBuffer:(BOOL)automaticBuffer
                      bufferFrames:(NSUInteger)bufferFrames
                        completion:(void (^)(NSString *_Nullable))completion {
    [self beginNetplayWithRole:moderngekko::frontend::NetplayRole::Join
                       address:address nickname:nickname port:port
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
            @"buffer": @(snapshot.buffer_frames),
            @"automaticBuffer": @(snapshot.adaptive_buffer),
            @"canStart": @(snapshot.can_start),
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
                        SsbmPadLog(@"netplay runtime error: %@", message);
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
    SsbmPadLog(@"runtime render scale=%ld source=live", (long)clamped);
}

- (void)applyAspectRatioMode:(SsbmPadAspectRatioMode)mode source:(NSString *)source {
    NSString *modeName = @"original-4:3";
    switch (mode) {
    case SsbmPadAspectRatioWidescreen:
        modeName = @"widescreen-16:9";
        Config::SetCurrent(Config::GFX_ASPECT_RATIO, AspectMode::ForceWide);
        Config::SetCurrent(Config::GFX_WIDESCREEN_HACK, true);
        break;
    case SsbmPadAspectRatioFillScreen: {
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
    case SsbmPadAspectRatioOriginal:
    default:
        Config::SetCurrent(Config::GFX_ASPECT_RATIO, AspectMode::ForceStandard);
        Config::SetCurrent(Config::GFX_WIDESCREEN_HACK, false);
        break;
    }
    SsbmPadLog(@"runtime aspect mode=%@ source=%@", modeName, source);
}

- (void)setAspectRatioMode:(SsbmPadAspectRatioMode)mode {
    if (!_running->load())
        return; // Runtime not booted yet; the mode applies at boot.
    [self applyAspectRatioMode:mode source:@"live"];
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
    return SsbmPadShouldApplyRightStickSmashForRevision0GameState(*gameState);
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
    SsbmPadLog(@"runtime stop requested starting=%d running=%d",
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
        SsbmPadLog(@"audio interruption latch cleared on foreground activation");
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
                SsbmPadLog(@"audio session deactivation failed: %@", audioError);
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
            SsbmPadLog(@"runtime paused for system event");
        } else {
            if (_systemStateRetryAttempts == 0 && pauseError)
                SsbmPadLog(@"runtime pause pending: %s", pauseError->message.c_str());
            else if (_systemStateRetryAttempts == 0 && hadRuntime)
                SsbmPadLog(@"runtime pause pending: core not yet pausable");
            else if (_systemStateRetryAttempts == 0)
                SsbmPadLog(@"runtime pause pending: runtime not created");
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
                SsbmPadLog(@"audio session reactivation pending: %@", audioError);
            [self scheduleSystemStateRetry];
            return;
        }
        _audioSessionNeedsReactivation = NO;
        _audioSessionDeactivatedForSystemEvent = NO;
        _systemStateRetryAttempts = 0;
        SsbmPadLog(@"audio session reactivated route=%@",
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
        SsbmPadLog(@"runtime resumed after system event");
    } else {
        if (_systemStateRetryAttempts == 0 && resumeError)
            SsbmPadLog(@"runtime resume pending: %s", resumeError->message.c_str());
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
    __weak SsbmPadCoreHost *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC),
                   dispatch_get_main_queue(), ^{
        SsbmPadCoreHost *strongSelf = weakSelf;
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
        SsbmPadLog(@"audio interruption began");
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
    SsbmPadLog(@"audio interruption ended shouldResume=%d", shouldResume);
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
    NSString *userDirectory = [paths.firstObject stringByAppendingPathComponent:@"SsbmPad"];
    [[NSFileManager defaultManager] createDirectoryAtPath:userDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    __weak SsbmPadCoreHost *weakSelf = self;
    [self startWithGameRoot:gameRoot
              discImagePath:discImagePath
                 modulePath:modulePath
              userDirectory:userDirectory
                    onError:^(NSString *message) {
        (void)weakSelf;
        NSLog(@"[SsbmPad] runtime error after restart: %@", message);
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
    delete _runtimeMutex;
    delete _netplaySession;
    delete _netplayServicesActive;
    delete _netplayBootInstalled;
}

@end
