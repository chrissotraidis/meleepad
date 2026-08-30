#import "SsbmPadGameViewController.h"

#import "SsbmPadCoreHost.h"
#import "SsbmPadControllerMapping.h"
#import "SsbmPadControllerSlots.h"
#import "SsbmPadDiagnostics.h"
#import "SsbmPadDiscExtractor.h"
#import "SsbmPadGameOverlay.h"
#import "SsbmPadInputMixer.h"
#import "SsbmPadSettings.h"

#import <CommonCrypto/CommonDigest.h>
#import <GameController/GameController.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <TargetConditionals.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#include <mach/mach.h>
#include <pthread.h>
#include <sys/resource.h>
#include <algorithm>
#include <cmath>
#include <unordered_map>
#include <vector>

static constexpr CGFloat SsbmPadDrawableScale = 1.0;
static NSString *const SsbmPadSupportedImageSHA256 =
    @"67cec1634e641227a4cd51e6a0b277730cb9a1adaa867530c9e66de45373e51d";

static uintptr_t SsbmPadControllerInstanceID(GCController *controller) {
    return reinterpret_cast<uintptr_t>((__bridge void *)controller);
}

static NSString *SsbmPadControllerInstanceName(uintptr_t instance) {
    return [NSString stringWithFormat:@"0x%llx", (unsigned long long)instance];
}

static GCControllerPlayerIndex SsbmPadPlayerIndexForSlot(NSInteger slot) {
    switch (slot) {
    case 0: return GCControllerPlayerIndex1;
    case 1: return GCControllerPlayerIndex2;
    case 2: return GCControllerPlayerIndex3;
    case 3: return GCControllerPlayerIndex4;
    default: return GCControllerPlayerIndexUnset;
    }
}

static NSString *SsbmPadThermalStateName(NSProcessInfoThermalState state) {
    switch (state) {
    case NSProcessInfoThermalStateFair: return @"fair";
    case NSProcessInfoThermalStateSerious: return @"serious";
    case NSProcessInfoThermalStateCritical: return @"critical";
    case NSProcessInfoThermalStateNominal:
    default: return @"nominal";
    }
}

static BOOL SsbmPadProcessUsage(double *cpuSeconds, double *residentMiB) {
    struct rusage usage = {};
    if (getrusage(RUSAGE_SELF, &usage) != 0)
        return NO;

    mach_task_basic_info_data_t info = {};
    mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), MACH_TASK_BASIC_INFO,
                                     reinterpret_cast<task_info_t>(&info), &count);
    if (result != KERN_SUCCESS)
        return NO;

    *cpuSeconds = (double)usage.ru_utime.tv_sec + (double)usage.ru_utime.tv_usec / 1e6 +
                  (double)usage.ru_stime.tv_sec + (double)usage.ru_stime.tv_usec / 1e6;
    *residentMiB = (double)info.resident_size / (1024.0 * 1024.0);
    return YES;
}

static NSString *SsbmPadTopThreadUsage(NSTimeInterval elapsed) {
    static std::unordered_map<uint64_t, double> previousCPUSeconds;
    if (elapsed <= 0.0)
        return @"unavailable";

    thread_act_array_t threads = nullptr;
    mach_msg_type_number_t threadCount = 0;
    if (task_threads(mach_task_self(), &threads, &threadCount) != KERN_SUCCESS)
        return @"unavailable";

    struct ThreadSample {
        double percent;
        std::string name;
    };
    std::vector<ThreadSample> samples;
    std::unordered_map<uint64_t, double> currentCPUSeconds;
    for (mach_msg_type_number_t index = 0; index < threadCount; ++index) {
        thread_identifier_info_data_t identifier = {};
        mach_msg_type_number_t identifierCount = THREAD_IDENTIFIER_INFO_COUNT;
        thread_basic_info_data_t basic = {};
        mach_msg_type_number_t basicCount = THREAD_BASIC_INFO_COUNT;
        if (thread_info(threads[index], THREAD_IDENTIFIER_INFO,
                        reinterpret_cast<thread_info_t>(&identifier), &identifierCount) == KERN_SUCCESS &&
            thread_info(threads[index], THREAD_BASIC_INFO,
                        reinterpret_cast<thread_info_t>(&basic), &basicCount) == KERN_SUCCESS) {
            double total = basic.user_time.seconds + basic.user_time.microseconds / 1e6 +
                           basic.system_time.seconds + basic.system_time.microseconds / 1e6;
            currentCPUSeconds[identifier.thread_id] = total;
            auto previous = previousCPUSeconds.find(identifier.thread_id);
            if (previous != previousCPUSeconds.end() && total >= previous->second) {
                char threadName[64] = {};
                pthread_t pthread = pthread_from_mach_thread_np(threads[index]);
                if (pthread != nullptr)
                    pthread_getname_np(pthread, threadName, sizeof(threadName));
                std::string name = threadName[0] != '\0' ? threadName : "unnamed";
                samples.push_back({100.0 * (total - previous->second) / elapsed,
                                   std::move(name)});
            }
        }
        mach_port_deallocate(mach_task_self(), threads[index]);
    }
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(threads),
                  threadCount * sizeof(thread_t));
    previousCPUSeconds = std::move(currentCPUSeconds);

    std::sort(samples.begin(), samples.end(), [](const ThreadSample& left,
                                                  const ThreadSample& right) {
        return left.percent > right.percent;
    });
    NSMutableArray<NSString *> *top = [NSMutableArray array];
    for (std::size_t index = 0; index < std::min<std::size_t>(samples.size(), 3); ++index) {
        [top addObject:[NSString stringWithFormat:@"%s:%.1f",
            samples[index].name.c_str(), samples[index].percent]];
    }
    return top.count > 0 ? [top componentsJoinedByString:@","] : @"baseline";
}

static SsbmPadPhysicalControllerButton SsbmPadPressedFaceButtons(GCExtendedGamepad *pad) {
    uint8_t buttons = 0;
    if (pad.buttonA.isPressed) buttons |= SsbmPadPhysicalControllerButtonA;
    if (pad.buttonB.isPressed) buttons |= SsbmPadPhysicalControllerButtonB;
    if (pad.buttonX.isPressed) buttons |= SsbmPadPhysicalControllerButtonX;
    if (pad.buttonY.isPressed) buttons |= SsbmPadPhysicalControllerButtonY;
    if (pad.leftShoulder.isPressed) buttons |= SsbmPadPhysicalControllerButtonLeftShoulder;
    return (SsbmPadPhysicalControllerButton)buttons;
}

static NSString *SsbmPadGameButtonName(uint16_t gameButton) {
    switch (gameButton) {
    case SsbmPadButtonA: return @"GameCube A";
    case SsbmPadButtonB: return @"GameCube B";
    case SsbmPadButtonX: return @"GameCube X";
    case SsbmPadButtonY: return @"GameCube Y";
    case SsbmPadButtonZ: return @"GameCube Z";
    default: return @"Unknown";
    }
}

static SsbmPadPhysicalControllerButton SsbmPadMappedPhysicalButton(
    SsbmPadControllerButtonMapping mapping, uint16_t gameButton) {
    switch (gameButton) {
    case SsbmPadButtonA: return mapping.gameA;
    case SsbmPadButtonB: return mapping.gameB;
    case SsbmPadButtonX: return mapping.gameX;
    case SsbmPadButtonY: return mapping.gameY;
    case SsbmPadButtonZ: return mapping.gameZ;
    default: return (SsbmPadPhysicalControllerButton)0;
    }
}

static NSString *_Nullable SsbmPadSHA256ForFile(NSString *path, NSError **error) {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (handle == nil) {
        if (error != nil) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSFileReadNoSuchFileError
                                     userInfo:@{NSFilePathErrorKey: path}];
        }
        return nil;
    }

    CC_SHA256_CTX context;
    CC_SHA256_Init(&context);
    while (true) {
        NSError *readError = nil;
        NSData *data = [handle readDataUpToLength:4 * 1024 * 1024 error:&readError];
        if (data == nil || readError != nil) {
            [handle closeFile];
            if (error != nil)
                *error = readError;
            return nil;
        }
        if (data.length == 0)
            break;
        CC_SHA256_Update(&context, data.bytes, (CC_LONG)data.length);
    }
    [handle closeFile];

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &context);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (unsigned char byte : digest)
        [hex appendFormat:@"%02x", byte];
    return hex;
}

static NSUInteger SsbmPadRegularFileCount(NSString *directory) {
    NSDirectoryEnumerator<NSString *> *enumerator =
        [[NSFileManager defaultManager] enumeratorAtPath:directory];
    NSUInteger count = 0;
    for (NSString *relative in enumerator) {
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager]
            fileExistsAtPath:[directory stringByAppendingPathComponent:relative]
                 isDirectory:&isDirectory];
        if (!isDirectory)
            ++count;
    }
    return count;
}

/* UIView whose backing layer is a CAMetalLayer: the ModernGekko Metal video
 * backend renders directly into this layer (Dolphin owns the drawable). */
@interface SsbmPadMetalSurfaceView : UIView
+ (Class)layerClass;
@end

@implementation SsbmPadMetalSurfaceView
+ (Class)layerClass {
    return [CAMetalLayer class];
}
@end

@interface SsbmPadGameViewController () <SsbmPadGameOverlayDelegate, UIDocumentPickerDelegate>
- (void)configureController:(GCController *)controller playerSlot:(NSInteger)slot;
- (nullable GCController *)controllerForPlayerSlot:(NSInteger)slot;
- (NSArray<NSURL *> *)gameImagesInDocumentsDirectory;
- (NSString *)modulePathFromConfiguration:(NSDictionary *)configuration;
- (void)presentGameDataImport;
- (void)presentGameDataFolderImport;
- (void)publishInputFromController:(GCController *)controller
                           gamepad:(GCExtendedGamepad *)gamepad;
- (void)reconcileControllersForReason:(NSString *)reason;
- (NSString *)resolvedImportTestPath:(NSString *)requestedPath;
- (void)showGameDataSetupState;
- (NSString *)sunPadSupportRoot;
@end

@implementation SsbmPadGameViewController {
    SsbmPadMetalSurfaceView *_gameView;
    SsbmPadCoreHost *_coreHost;
    SsbmPadGameOverlay *_overlay;
    dispatch_source_t _controllerTimer;
    UILabel *_fpsLabel;
    UILabel *_bootStatusLabel;
    UIActivityIndicatorView *_bootActivityIndicator;
    UIButton *_gameDataImportButton;
    SsbmPadControllerSlots _controllerSlots;
    NSMutableDictionary<NSNumber *, GCController *> *_configuredControllers;
    CGSize _lastLoggedDrawableSize;
    NSUInteger _performanceLogSeconds;
    double _lastPerformanceCPUSeconds;
    NSTimeInterval _lastPerformanceUptime;
    BOOL _hasPerformanceUsageBaseline;
    NSString *_lastPerformanceSummary;
    NSDate *_lastScreenshotMarker;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // Super Smash Bros. Melee is a landscape game; the overlay is designed for
    // landscape like the BellPad reference (never portrait).
    return UIInterfaceOrientationMaskLandscape;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    SsbmPadLog(@"viewDidLoad bounds=%@ orientation=%ld",
              NSStringFromCGRect(self.view.bounds), (long)UIDevice.currentDevice.orientation);
    SsbmPadLog(@"game mode eligibility declared=%d",
              [[NSBundle.mainBundle objectForInfoDictionaryKey:@"LSSupportsGameMode"] boolValue]);
    self.view.backgroundColor = UIColor.blackColor;

    _gameView = [[SsbmPadMetalSurfaceView alloc] initWithFrame:self.view.bounds];
    _gameView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_gameView];

    CAMetalLayer *layer = (CAMetalLayer *)_gameView.layer;
    layer.device = MTLCreateSystemDefaultDevice();
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;
    layer.drawableSize = CGSizeMake(CGRectGetWidth(_gameView.bounds) * SsbmPadDrawableScale,
                                    CGRectGetHeight(_gameView.bounds) * SsbmPadDrawableScale);

    _overlay = [[SsbmPadGameOverlay alloc] initWithFrame:self.view.bounds];
    _overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _overlay.delegate = self;
    [self.view addSubview:_overlay];

    _bootActivityIndicator = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _bootActivityIndicator.color = UIColor.whiteColor;
    _bootActivityIndicator.hidesWhenStopped = YES;
    [_bootActivityIndicator startAnimating];
    [self.view addSubview:_bootActivityIndicator];

    _bootStatusLabel = [UILabel new];
    _bootStatusLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    _bootStatusLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    _bootStatusLabel.textAlignment = NSTextAlignmentCenter;
    _bootStatusLabel.numberOfLines = 0;
    _bootStatusLabel.text = @"Preparing runtime…";
    _bootStatusLabel.accessibilityLabel = @"Preparing runtime";
    [self.view addSubview:_bootStatusLabel];

    _gameDataImportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *importConfiguration =
        [UIButtonConfiguration filledButtonConfiguration];
    importConfiguration.title = @"Choose ISO or GCM";
    importConfiguration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    importConfiguration.baseBackgroundColor = UIColor.systemBlueColor;
    importConfiguration.baseForegroundColor = UIColor.whiteColor;
    importConfiguration.contentInsets = NSDirectionalEdgeInsetsMake(14.0, 24.0, 14.0, 24.0);
    _gameDataImportButton.configuration = importConfiguration;
    _gameDataImportButton.accessibilityHint =
        @"Opens Files to select supported Super Smash Bros. Melee game data.";
    [_gameDataImportButton addTarget:self
                              action:@selector(presentGameDataImport)
                    forControlEvents:UIControlEventTouchUpInside];
    _gameDataImportButton.hidden = YES;
    [self.view addSubview:_gameDataImportButton];

    _configuredControllers = [NSMutableDictionary dictionary];

    _fpsLabel = [UILabel new];
    _fpsLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.85];
    _fpsLabel.font = [UIFont monospacedDigitSystemFontOfSize:12.0
                                                      weight:UIFontWeightSemibold];
    _fpsLabel.text = @"";
    _fpsLabel.hidden = YES;
    [self.view addSubview:_fpsLabel];
    [self startFPSMonitor];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidTakeScreenshot:)
                                                 name:UIApplicationUserDidTakeScreenshotNotification
                                               object:nil];
    // SsbmPad is an app-delegate UIKit app rather than a scene-based app. These
    // legacy notifications remain the only direct external-screen signal for
    // this deployment model on iPadOS 16+.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayConfigurationChanged:)
                                                 name:UIScreenDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayConfigurationChanged:)
                                                 name:UIScreenDidDisconnectNotification
                                               object:nil];
#pragma clang diagnostic pop
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayConfigurationChanged:)
                                                 name:UIScreenModeDidChangeNotification
                                               object:nil];
    // DEBUG hook: -ssbmpadImportTest <iso path> runs the full import flow.
    NSArray<NSString *> *arguments = NSProcessInfo.processInfo.arguments;
    NSUInteger importIndex = [arguments indexOfObject:@"-ssbmpadImportTest"];
    if (importIndex != NSNotFound && importIndex + 1 < arguments.count) {
        NSString *imagePath = [self resolvedImportTestPath:arguments[importIndex + 1]];
        NSLog(@"[SsbmPad] import test requested=%@ resolved=%@", arguments[importIndex + 1], imagePath);
        [self startInputConsumer];
        [self observeControllers];
        [self importGameDataFromURL:[NSURL fileURLWithPath:imagePath]];
        return;
    }
    [self startGameIfProvisioned];
    [self startInputConsumer];
    [self observeControllers];
}

// Physical-device launches cannot refer to the host's /tmp. devicectl copies
// into the app data container, whose actual temporary directory is returned by
// NSTemporaryDirectory(). Keep the command-line hook usable for both the
// Simulator's host path and the device's injected ISO.
- (NSString *)resolvedImportTestPath:(NSString *)requestedPath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:requestedPath])
        return requestedPath;
    NSString *prefix = @"/tmp/";
    if ([requestedPath hasPrefix:prefix]) {
        NSString *relativePath = [requestedPath substringFromIndex:prefix.length];
        NSString *sandboxPath = [NSTemporaryDirectory() stringByAppendingPathComponent:relativePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:sandboxPath])
            return sandboxPath;
    }
    return requestedPath;
}

- (NSString *)modulePathFromConfiguration:(NSDictionary *)configuration {
    NSString *hostPath = configuration[@"DevModulePath"];
    if (hostPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:hostPath])
        return hostPath;

    NSString *deviceRelativePath = configuration[@"DeviceModuleRelativePath"];
#if !TARGET_OS_SIMULATOR
    // Simulator and device provisioning share a generated development plist.
    // A Simulator build may therefore leave DevModulePath pointing at the Mac.
    // Device installs always use this stable, sandbox-relative module name.
    if (deviceRelativePath.length == 0)
        deviceRelativePath = @"gGALE01_recomp.dylib";
#endif
    if (deviceRelativePath.length > 0) {
        NSString *temporaryPath =
            [NSTemporaryDirectory() stringByAppendingPathComponent:deviceRelativePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPath])
            return temporaryPath;

        // Local device builds can carry the signed, user-generated module in
        // the app bundle when CoreDevice temporary-file uploads are unavailable.
        NSString *bundledPath =
            [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:deviceRelativePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:bundledPath])
            return bundledPath;
        return temporaryPath;
    }
    return hostPath;
}

- (void)startFPSMonitor {
    static dispatch_source_t fpsTimer;
    if (fpsTimer)
        return;
    fpsTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                      dispatch_get_main_queue());
    dispatch_source_set_timer(fpsTimer, dispatch_time(DISPATCH_TIME_NOW, 0),
                              1.0 * NSEC_PER_SEC, 0);
    __weak SsbmPadGameViewController *weakSelf = self;
    dispatch_source_set_event_handler(fpsTimer, ^{
        [weakSelf updateFPSLabel];
    });
    dispatch_resume(fpsTimer);
}

- (void)updateFPSLabel {
    [self reconcileControllersForReason:@"periodic"];
    BOOL applicationActive = UIApplication.sharedApplication.applicationState ==
        UIApplicationStateActive;
    double fps = applicationActive ? [_coreHost currentFPS] : 0.0;
    if (!applicationActive) {
        _performanceLogSeconds = 0;
        _hasPerformanceUsageBaseline = NO;
    }
    if (fps > 0.0) {
        _bootStatusLabel.hidden = YES;
        [_bootActivityIndicator stopAnimating];
        if (++_performanceLogSeconds >= 10) {
            _performanceLogSeconds = 0;
            NSProcessInfo *processInfo = NSProcessInfo.processInfo;
            double cpuSeconds = 0.0;
            double residentMiB = 0.0;
            NSTimeInterval uptime = processInfo.systemUptime;
            BOOL hasUsage = SsbmPadProcessUsage(&cpuSeconds, &residentMiB);
            double appCPUPercent = -1.0;
            NSTimeInterval usageInterval = 0.0;
            if (hasUsage && _hasPerformanceUsageBaseline &&
                uptime > _lastPerformanceUptime) {
                usageInterval = uptime - _lastPerformanceUptime;
                appCPUPercent = 100.0 * (cpuSeconds - _lastPerformanceCPUSeconds) /
                                usageInterval;
            }
            if (hasUsage) {
                _lastPerformanceCPUSeconds = cpuSeconds;
                _lastPerformanceUptime = uptime;
                _hasPerformanceUsageBaseline = YES;
            }
            NSString *topThreads = SsbmPadTopThreadUsage(usageInterval);
            _lastPerformanceSummary = [NSString stringWithFormat:
                @"fps=%.1f vps=%.1f speedRatio=%.3f efb=%@ renderScale=%ld aspect=%ld "
                 @"thermal=%@ lowPower=%d appCPU=%.1f residentMiB=%.1f topThreads=%@",
                      fps, [_coreHost currentVPS], [_coreHost currentSpeed],
                      [_coreHost efbResolution],
                      (long)[SsbmPadSettings sharedSettings].renderScale,
                      (long)[SsbmPadSettings sharedSettings].aspectRatioMode,
                      SsbmPadThermalStateName(processInfo.thermalState),
                      processInfo.isLowPowerModeEnabled, appCPUPercent, residentMiB,
                      topThreads];
            NSString *graphics = [[_coreHost diagnosticSummary]
                stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            SsbmPadLog(@"performance %@ %@", _lastPerformanceSummary, graphics);
        }
    } else if (_coreHost != nil && !_bootStatusLabel.hidden &&
               _bootActivityIndicator.isAnimating) {
        _performanceLogSeconds = 0;
        _bootStatusLabel.text = @"Waiting for first frame…";
        _bootStatusLabel.accessibilityLabel = @"Waiting for first frame";
    }

    if (![SsbmPadSettings sharedSettings].showFPSCounter) {
        _fpsLabel.hidden = YES;
        return;
    }
    if (fps > 0.0) {
        // Melee is a native 60 FPS game. Speed and VPS are retained in the
        // diagnostic telemetry rather than cluttering this overlay.
        _fpsLabel.text = [NSString stringWithFormat:@"%.1f FPS", fps];
        _fpsLabel.hidden = NO;
        NSLog(@"[SsbmPad] FPS: %.1f  EFB: %@", fps, [_coreHost efbResolution]);
    } else {
        _fpsLabel.hidden = YES;
    }
}

- (void)userDidTakeScreenshot:(NSNotification *)notification {
    (void)notification;
    _lastScreenshotMarker = NSDate.date;
    NSString *context = [[self gameOverlayDiagnosticContext:_overlay]
        stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    SsbmPadLog(@"diagnostic marker reason=user-screenshot %@", context);
}

- (void)observeControllers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controllerDidConnect:)
                                                 name:GCControllerDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controllerDidDisconnect:)
                                                 name:GCControllerDidDisconnectNotification
                                               object:nil];
    [self reconcileControllersForReason:@"launch"];
}

- (void)controllerDidConnect:(NSNotification *)notification {
    GCController *controller = notification.object;
    uintptr_t instance = SsbmPadControllerInstanceID(controller);
    SsbmPadLog(@"controller connected instance=%@ vendor=%@ category=%@ extended=%d count=%lu",
              SsbmPadControllerInstanceName(instance),
              controller.vendorName ?: @"unknown", controller.productCategory ?: @"unknown",
              controller.extendedGamepad != nil, (unsigned long)GCController.controllers.count);
    [self reconcileControllersForReason:@"connect"];
}

- (void)controllerDidDisconnect:(NSNotification *)notification {
    GCController *controller = notification.object;
    uintptr_t instance = SsbmPadControllerInstanceID(controller);
    NSInteger slot = _controllerSlots.SlotFor(instance);
    SsbmPadLog(@"controller disconnected instance=%@ slot=%ld vendor=%@ count=%lu",
              SsbmPadControllerInstanceName(instance), (long)(slot >= 0 ? slot + 1 : 0),
              controller.vendorName ?: @"unknown", (unsigned long)GCController.controllers.count);
    [self reconcileControllersForReason:@"disconnect"];
}

/* Analog triggers carry L/R pressure (FLUDD), the left shoulder is Z,
 * the right shoulder is medium analog R, menu is Start, and the D-pad maps
 * to D-pad bits. */
- (void)configureController:(GCController *)controller playerSlot:(NSInteger)slot {
    GCExtendedGamepad *gamepad = controller.extendedGamepad;
    if (gamepad == nil) {
        SsbmPadLog(@"controller ignored instance=%@ vendor=%@ reason=no extended gamepad profile",
                  SsbmPadControllerInstanceName(SsbmPadControllerInstanceID(controller)),
                  controller.vendorName ?: @"unknown");
        return;
    }
    SsbmPadLog(@"controller configured instance=%@ slot=%ld vendor=%@ category=%@",
              SsbmPadControllerInstanceName(SsbmPadControllerInstanceID(controller)),
              (long)(slot + 1), controller.vendorName ?: @"unknown",
              controller.productCategory ?: @"unknown");
    __weak SsbmPadGameViewController *weakSelf = self;
    __weak GCController *weakController = controller;
    gamepad.valueChangedHandler = ^(GCExtendedGamepad *pad, GCControllerElement *element) {
        (void)element;
        dispatch_async(dispatch_get_main_queue(), ^{
            SsbmPadGameViewController *strongSelf = weakSelf;
            GCController *strongController = weakController;
            if (strongSelf != nil && strongController != nil)
                [strongSelf publishInputFromController:strongController gamepad:pad];
        });
    };
    [self publishInputFromController:controller gamepad:gamepad];
}

- (void)publishInputFromController:(GCController *)controller
                           gamepad:(GCExtendedGamepad *)gamepad {
    NSArray<GCController *> *currentControllers = GCController.controllers;
    if ([currentControllers indexOfObjectIdenticalTo:controller] == NSNotFound) {
        uintptr_t instance = SsbmPadControllerInstanceID(controller);
        SsbmPadLog(@"controller stale callback instance=%@ slot=%ld action=reconcile",
                  SsbmPadControllerInstanceName(instance),
                  (long)(_controllerSlots.SlotFor(instance) + 1));
        [self reconcileControllersForReason:@"stale-callback"];
        return;
    }

    uintptr_t instance = SsbmPadControllerInstanceID(controller);
    if (_controllerSlots.SlotFor(instance) != 0)
        return;

    // Every callback is a complete snapshot. Leaving buttons uninitialized
    // made random button edges overflow the old fixed-size pipe buffer.
    SsbmPadInputState state = {};
    state.connected = 1;
    state.buttons |= SsbmPadApplyControllerButtonMapping(
        [SsbmPadControllerMappingStore mapping], SsbmPadPressedFaceButtons(gamepad));
    if (gamepad.buttonMenu.isPressed) state.buttons |= SsbmPadButtonStart;
    if (gamepad.dpad.up.isPressed) state.buttons |= SsbmPadButtonDpadUp;
    if (gamepad.dpad.down.isPressed) state.buttons |= SsbmPadButtonDpadDown;
    if (gamepad.dpad.left.isPressed) state.buttons |= SsbmPadButtonDpadLeft;
    if (gamepad.dpad.right.isPressed) state.buttons |= SsbmPadButtonDpadRight;
    state.stickX = (int8_t)std::lround(gamepad.leftThumbstick.xAxis.value * 127.0f);
    state.stickY = (int8_t)std::lround(gamepad.leftThumbstick.yAxis.value * 127.0f);
    state.cStickX = (int8_t)std::lround(gamepad.rightThumbstick.xAxis.value * 127.0f);
    state.cStickY = (int8_t)std::lround(gamepad.rightThumbstick.yAxis.value * 127.0f);
    state.triggerL = (uint8_t)std::lround(gamepad.leftTrigger.value * 255.0f);
    uint8_t physicalTriggerR =
        (uint8_t)std::lround(gamepad.rightTrigger.value * 255.0f);
    state.triggerR = SsbmPadControllerRightTriggerPressure(
        physicalTriggerR, gamepad.rightShoulder.isPressed);
    if (state.triggerL > 30) state.buttons |= SsbmPadButtonL;
    if (physicalTriggerR > 30) state.buttons |= SsbmPadButtonR;
    [[SsbmPadInputMixer sharedMixer] setInputState:state fromTouch:NO];
}

- (void)reconcileControllersForReason:(NSString *)reason {
    NSArray<GCController *> *currentControllers = GCController.controllers;
    std::vector<uintptr_t> currentInstances;
    for (GCController *controller in currentControllers) {
        if (controller.extendedGamepad != nil)
            currentInstances.push_back(SsbmPadControllerInstanceID(controller));
    }

    SsbmPadControllerReconcileResult result = _controllerSlots.Reconcile(currentInstances);
    for (const SsbmPadControllerSlotChange &change : result.removed) {
        NSNumber *key = @(change.instance);
        GCController *staleController = _configuredControllers[key];
        staleController.extendedGamepad.valueChangedHandler = nil;
        staleController.playerIndex = GCControllerPlayerIndexUnset;
        [_configuredControllers removeObjectForKey:key];
        if (change.slot == 0)
            [[SsbmPadInputMixer sharedMixer] clearInputFromTouch:NO];
        SsbmPadLog(@"controller reconciled reason=%@ instance=%@ slot=%ld status=%@",
                  reason, SsbmPadControllerInstanceName(change.instance),
                  (long)(change.slot + 1), @"removed");
    }

    if (!result.removed.empty() || !result.assigned.empty())
        [_overlay refreshControllerVisibility];

    BOOL logRetained = ![reason isEqualToString:@"periodic"];
    for (GCController *controller in currentControllers) {
        if (controller.extendedGamepad == nil)
            continue;
        uintptr_t instance = SsbmPadControllerInstanceID(controller);
        NSInteger slot = _controllerSlots.SlotFor(instance);
        if (slot < 0) {
            if (logRetained) {
                SsbmPadLog(@"controller reconciled reason=%@ instance=%@ slot=0 status=%@",
                          reason, SsbmPadControllerInstanceName(instance), @"no-free-slot");
            }
            continue;
        }

        NSNumber *key = @(instance);
        BOOL newlyConfigured = _configuredControllers[key] != controller;
        controller.playerIndex = SsbmPadPlayerIndexForSlot(slot);
        if (newlyConfigured) {
            _configuredControllers[key] = controller;
            [self configureController:controller playerSlot:slot];
        }
        if (newlyConfigured || logRetained) {
            SsbmPadLog(@"controller reconciled reason=%@ instance=%@ slot=%ld status=%@",
                      reason, SsbmPadControllerInstanceName(instance), (long)(slot + 1),
                      newlyConfigured ? @"assigned" : @"retained");
        }
    }

    GCController *playerOne = [self controllerForPlayerSlot:0];
    if (playerOne != nil)
        [self publishInputFromController:playerOne gamepad:playerOne.extendedGamepad];
}

- (nullable GCController *)controllerForPlayerSlot:(NSInteger)slot {
    if (slot < 0 || slot >= (NSInteger)SsbmPadControllerSlots::kMaxPlayers)
        return nil;
    uintptr_t instance = _controllerSlots.InstanceAt((std::size_t)slot);
    return instance == 0 ? nil : _configuredControllers[@(instance)];
}

- (void)settingsChanged:(NSNotification *)notification {
    (void)notification;
    SsbmPadSettings *settings = [SsbmPadSettings sharedSettings];
    [_coreHost setRenderScale:settings.renderScale];
    [_coreHost setAspectRatioMode:settings.aspectRatioMode];
    [self updateFPSLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CAMetalLayer *layer = (CAMetalLayer *)_gameView.layer;
    layer.drawableSize = CGSizeMake(CGRectGetWidth(_gameView.bounds) * SsbmPadDrawableScale,
                                    CGRectGetHeight(_gameView.bounds) * SsbmPadDrawableScale);
    if (!CGSizeEqualToSize(_lastLoggedDrawableSize, layer.drawableSize)) {
        _lastLoggedDrawableSize = layer.drawableSize;
        SsbmPadLog(@"layout bounds=%@ game=%@ drawable=%@",
                  NSStringFromCGRect(self.view.bounds),
                  NSStringFromCGRect(_gameView.bounds),
                  NSStringFromCGSize(layer.drawableSize));
    }
    CGRect safe = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets);
    CGFloat statusWidth = MIN(420.0, CGRectGetWidth(safe) - 32.0);
    _bootActivityIndicator.center = CGPointMake(CGRectGetMidX(safe),
                                                CGRectGetMidY(safe) - 34.0);
    if (_gameDataImportButton.hidden) {
        _bootStatusLabel.frame = CGRectMake(CGRectGetMidX(safe) - statusWidth / 2.0,
                                            CGRectGetMidY(safe) - 4.0,
                                            statusWidth, 80.0);
    } else {
        _bootStatusLabel.frame = CGRectMake(CGRectGetMidX(safe) - statusWidth / 2.0,
                                            CGRectGetMidY(safe) - 104.0,
                                            statusWidth, 132.0);
    }
    CGFloat importWidth = MIN(240.0, CGRectGetWidth(safe) - 64.0);
    _gameDataImportButton.frame = CGRectMake(CGRectGetMidX(safe) - importWidth / 2.0,
                                             CGRectGetMidY(safe) + 44.0,
                                             importWidth, 50.0);
    _fpsLabel.frame = CGRectMake(CGRectGetMinX(safe) + 8.0,
                                 CGRectGetMinY(safe) + 8.0,
                                 140.0, 22.0);
}

- (void)displayConfigurationChanged:(NSNotification *)notification {
    UIScreen *screen = [notification.object isKindOfClass:UIScreen.class]
        ? notification.object : UIScreen.mainScreen;
    SsbmPadLog(@"display event=%@ bounds=%@ nativeBounds=%@ scale=%.2f nativeScale=%.2f maxFPS=%ld",
              notification.name,
              NSStringFromCGRect(screen.bounds), NSStringFromCGRect(screen.nativeBounds),
              screen.scale, screen.nativeScale, (long)screen.maximumFramesPerSecond);
}

- (void)startGameIfProvisioned {
    if (_coreHost != nil)
        return;
    _gameDataImportButton.hidden = YES;
    _bootStatusLabel.hidden = NO;
    _bootStatusLabel.text = @"Preparing runtime…";
    _bootStatusLabel.accessibilityLabel = @"Preparing runtime";
    [_bootActivityIndicator startAnimating];
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *configPath = [bundle pathForResource:@"dev-config" ofType:@"plist"];
    if (configPath == nil) {
        SsbmPadLog(@"boot skipped reason=dev config missing");
        _bootStatusLabel.text = @"SsbmPad needs its local game data before it can start.";
        _bootStatusLabel.accessibilityLabel = _bootStatusLabel.text;
        [_bootActivityIndicator stopAnimating];
        return; // Not a dev-provisioned build; import flow is a later stage.
    }
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:configPath];
    SsbmPadSettings *settings = [SsbmPadSettings sharedSettings];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // App updates can relocate the data-container UUID. On physical devices,
    // derive imported data from the current sandbox instead of trusting an
    // absolute path persisted by a previous installation.
    NSString *supportRoot = [self sunPadSupportRoot];
    NSString *gameDataDirectory = [supportRoot stringByAppendingPathComponent:@"GameData"];

    // Side-by-side diagnostic builds may carry a known progressed save so a
    // performance run can begin in representative gameplay. Seed it exactly
    // once per identifier; production configurations omit these keys.
    NSString *bundledSaveRelativePath = config[@"DeviceBundledSaveRelativePath"];
    NSString *bundledSaveSeedID = config[@"DeviceBundledSaveSeedID"];
    NSString *saveSeedPreference = @"SsbmPadDeviceBundledSaveSeedID";
    if (bundledSaveRelativePath.length > 0 && bundledSaveSeedID.length > 0 &&
        ![[[NSUserDefaults standardUserDefaults] stringForKey:saveSeedPreference]
            isEqualToString:bundledSaveSeedID]) {
        NSString *bundledSave =
            [bundle.bundlePath stringByAppendingPathComponent:bundledSaveRelativePath];
        NSString *saveDirectory = [supportRoot
            stringByAppendingPathComponent:@"GC/USA/Card A"];
        NSString *saveDestination = [saveDirectory
            stringByAppendingPathComponent:bundledSave.lastPathComponent];
        NSError *saveError = nil;
        [fileManager createDirectoryAtPath:saveDirectory
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:&saveError];
        if (saveError == nil) {
            NSString *temporarySave = [saveDestination stringByAppendingString:@".seed"];
            [fileManager removeItemAtPath:temporarySave error:nil];
            if ([fileManager copyItemAtPath:bundledSave toPath:temporarySave error:&saveError]) {
                [fileManager removeItemAtPath:saveDestination error:nil];
                if ([fileManager moveItemAtPath:temporarySave
                                         toPath:saveDestination
                                          error:&saveError]) {
                    [[NSUserDefaults standardUserDefaults]
                        setObject:bundledSaveSeedID forKey:saveSeedPreference];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    SsbmPadLog(@"diagnostic save seeded file=%@ id=%@",
                              saveDestination.lastPathComponent, bundledSaveSeedID);
                }
            }
        }
        if (saveError != nil)
            SsbmPadLog(@"diagnostic save seed failed: %@", saveError);
    }

    NSString *currentContainerRoot = [gameDataDirectory stringByAppendingPathComponent:@"GALE01"];
    BOOL currentRootExists = [fileManager fileExistsAtPath:currentContainerRoot];
    NSString *gameRoot = currentContainerRoot;
#if TARGET_OS_SIMULATOR
    if (!currentRootExists) {
        NSString *developmentRoot = config[@"DevGameRoot"];
        if (developmentRoot.length > 0)
            gameRoot = developmentRoot;
    }
#else
    // A side-by-side diagnostic build can be made self-contained when the
    // CoreDevice data-container transfer service is unavailable. Production
    // builds omit this key and continue to require imported sandbox data.
    if (!currentRootExists) {
        NSString *bundledRootRelativePath = config[@"DeviceBundledGameRootRelativePath"];
        NSString *bundledRoot = bundledRootRelativePath.length > 0
            ? [bundle.bundlePath stringByAppendingPathComponent:bundledRootRelativePath] : nil;
        if (bundledRoot.length > 0 && [fileManager fileExistsAtPath:bundledRoot])
            gameRoot = bundledRoot;
    }
#endif
    if (![settings.extractedGameRoot isEqualToString:gameRoot]) {
        settings.extractedGameRoot = gameRoot;
        [settings synchronize];
    }
    SsbmPadLog(@"boot data support=%@ root=%@ rootExists=%d persistedRoot=%@",
              supportRoot, gameRoot, currentRootExists,
              settings.extractedGameRoot ?: @"none");

    BOOL gameRootIsDirectory = NO;
    BOOL gameRootExists =
        [fileManager fileExistsAtPath:gameRoot isDirectory:&gameRootIsDirectory];
    BOOL gameRootReadable = gameRootExists && gameRootIsDirectory &&
                            [fileManager isReadableFileAtPath:gameRoot];
    if (!gameRootReadable) {
        SsbmPadLog(@"boot waiting for game data rootExists=%d directory=%d readable=%d",
                  gameRootExists, gameRootIsDirectory,
                  gameRootExists && [fileManager isReadableFileAtPath:gameRoot]);
        [self showGameDataSetupState];
        return;
    }

    NSString *modulePath = [self modulePathFromConfiguration:config];
    if (gameRoot.length == 0 || modulePath.length == 0) {
        SsbmPadLog(@"boot skipped gameRoot=%d modulePath=%d",
                  gameRoot.length > 0, modulePath.length > 0);
        _bootStatusLabel.text = @"SsbmPad could not find its local game data.";
        _bootStatusLabel.accessibilityLabel = _bootStatusLabel.text;
        [_bootActivityIndicator stopAnimating];
        return;
    }

    NSString *userDirectory = supportRoot;
    [[NSFileManager defaultManager] createDirectoryAtPath:userDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    // Boot from the retained image so Dolphin sees the exact FST, physical
    // file offsets, and streaming layout from the user's disc. In-place app
    // installs preserve the file but change the container UUID, so rebase the
    // persisted absolute path when necessary.
    NSString *discFileName = settings.retainedGameDataPath.lastPathComponent;
    if (discFileName.length == 0) {
        NSArray<NSString *> *entries = [fileManager contentsOfDirectoryAtPath:gameDataDirectory
                                                                        error:nil];
        for (NSString *entry in entries) {
            NSString *extension = entry.pathExtension.lowercaseString;
            if ([extension isEqualToString:@"iso"] ||
                [extension isEqualToString:@"gcm"] ||
                [extension isEqualToString:@"rvz"]) {
                discFileName = entry;
                break;
            }
        }
    }
    NSString *rebasedImage = discFileName.length > 0
        ? [gameDataDirectory stringByAppendingPathComponent:discFileName] : @"";
    NSString *discImagePath = rebasedImage;
#if TARGET_OS_SIMULATOR
    if (rebasedImage.length == 0 || ![fileManager fileExistsAtPath:rebasedImage])
        discImagePath = settings.retainedGameDataPath ?: @"";
#else
    if (rebasedImage.length == 0 || ![fileManager fileExistsAtPath:rebasedImage]) {
        NSString *bundledDiscRelativePath = config[@"DeviceBundledDiscImageRelativePath"];
        NSString *bundledDisc = bundledDiscRelativePath.length > 0
            ? [bundle.bundlePath stringByAppendingPathComponent:bundledDiscRelativePath] : nil;
        if (bundledDisc.length > 0 && [fileManager fileExistsAtPath:bundledDisc])
            discImagePath = bundledDisc;
    }
#endif
    if (discImagePath.length > 0 &&
        ![settings.retainedGameDataPath isEqualToString:discImagePath]) {
        settings.retainedGameDataPath = discImagePath;
        [settings synchronize];
    }
    SsbmPadLog(@"boot disc path=%@ exists=%d", discImagePath.length > 0
              ? discImagePath.lastPathComponent : @"none",
              discImagePath.length > 0 && [fileManager fileExistsAtPath:discImagePath]);

    CAMetalLayer *layer = (CAMetalLayer *)_gameView.layer;
    SsbmPadLog(@"boot requested gameRootExists=%d discImage=%d moduleExists=%d drawable=%@",
              [fileManager fileExistsAtPath:gameRoot], discImagePath.length > 0,
              [fileManager fileExistsAtPath:modulePath], NSStringFromCGSize(layer.drawableSize));
    _coreHost = [[SsbmPadCoreHost alloc] initWithLayer:layer];
    __weak SsbmPadGameViewController *weakSelf = self;
    _bootStatusLabel.text = @"Starting game…";
    _bootStatusLabel.accessibilityLabel = @"Starting game";
    [_coreHost startWithGameRoot:gameRoot
                   discImagePath:discImagePath ?: @""
                      modulePath:modulePath
                   userDirectory:userDirectory
                         onError:^(NSString *message) {
        [weakSelf presentBootError:message];
    }];
}

- (void)showGameDataSetupState {
    [_bootActivityIndicator stopAnimating];
    _bootStatusLabel.hidden = NO;

    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.alignment = NSTextAlignmentCenter;
    paragraph.paragraphSpacing = 8.0;
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold],
        NSForegroundColorAttributeName: UIColor.whiteColor,
        NSParagraphStyleAttributeName: paragraph,
    };
    NSDictionary *bodyAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.82],
        NSParagraphStyleAttributeName: paragraph,
    };
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc]
        initWithString:@"Game data required\n" attributes:titleAttributes];
    [message appendAttributedString:[[NSAttributedString alloc]
        initWithString:@"SsbmPad does not include game files. Choose your own legally obtained Super Smash Bros. Melee USA disc image (GALE01, revision 0) to continue."
             attributes:bodyAttributes]];
    _bootStatusLabel.attributedText = message;
    _bootStatusLabel.accessibilityLabel =
        @"Game data required. SsbmPad does not include game files. Choose your own legally obtained Super Smash Bros. Melee USA disc image, GALE01 revision zero, to continue.";
    _gameDataImportButton.hidden = NO;
    [self.view setNeedsLayout];
}

- (void)presentBootError:(NSString *)message {
    _bootStatusLabel.text = @"SsbmPad could not start.";
    _bootStatusLabel.accessibilityLabel = _bootStatusLabel.text;
    [_bootActivityIndicator stopAnimating];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"SsbmPad could not start"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)startInputConsumer {
    // Feed the game thread the merged touch+controller snapshot at 60 Hz.
    if (_controllerTimer)
        return;
    _controllerTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                              dispatch_get_main_queue());
    dispatch_source_set_timer(_controllerTimer, dispatch_time(DISPATCH_TIME_NOW, 0),
                              1.0 / 60.0 * NSEC_PER_SEC, 0);
    __weak SsbmPadGameViewController *weakSelf = self;
    dispatch_source_set_event_handler(_controllerTimer, ^{
        [weakSelf publishMergedInput];
    });
    dispatch_resume(_controllerTimer);
}

- (void)publishMergedInput {
    SsbmPadInputState merged = [[SsbmPadInputMixer sharedMixer] consumeMergedState];
    [_coreHost publishInput:merged];
}

- (void)pauseRuntimeForApplicationLifecycle {
    _performanceLogSeconds = 0;
    _hasPerformanceUsageBaseline = NO;
    [_coreHost pauseRuntimeForSystemEvent];
}

- (void)resumeRuntimeForApplicationLifecycle {
    _performanceLogSeconds = 0;
    _hasPerformanceUsageBaseline = NO;
    [self reconcileControllersForReason:@"foreground"];
    [_overlay refreshControllerVisibility];
    [_coreHost resumeRuntimeAfterSystemEvent];
}

#pragma mark - SsbmPadGameOverlayDelegate

- (void)gameOverlayRequestsGameDataChange:(SsbmPadGameOverlay *)overlay {
    (void)overlay;
    // Document-picker game-data import flow is wired in the app delegate; the
    // overlay requests a change/reimport here.
    [self presentGameDataImport];
}

- (void)gameOverlayRequestsGameDataFolderImport:(SsbmPadGameOverlay *)overlay {
    (void)overlay;
    [self presentGameDataFolderImport];
}

- (void)gameOverlayRequestsGameDataRemoval:(SsbmPadGameOverlay *)overlay {
    (void)overlay;
    if (_coreHost != nil) {
        [_coreHost stop];
        _coreHost = nil;
    }

    NSString *dataDirectory = [[self sunPadSupportRoot]
        stringByAppendingPathComponent:@"GameData"];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataDirectory] &&
        ![[NSFileManager defaultManager] removeItemAtPath:dataDirectory error:&error]) {
        [self startGameIfProvisioned];
        [self presentBootError:[NSString stringWithFormat:
            @"Could not remove stored game data: %@", error.localizedDescription]];
        return;
    }

    SsbmPadSettings *settings = [SsbmPadSettings sharedSettings];
    settings.retainedGameDataPath = nil;
    settings.extractedGameRoot = nil;
    [settings synchronize];
    [self showGameDataSetupState];
    SsbmPadLog(@"stored game data removed");
}

- (void)gameOverlayRequestsControllerMapping:(SsbmPadGameOverlay *)overlay {
    (void)overlay;
    [self presentControllerMapping];
}

- (NSString *)gameOverlayDiagnosticContext:(SsbmPadGameOverlay *)overlay {
    (void)overlay;
    NSBundle *bundle = NSBundle.mainBundle;
    SsbmPadSettings *settings = [SsbmPadSettings sharedSettings];
    NSMutableArray<NSString *> *controllers = [NSMutableArray array];
    for (GCController *controller in GCController.controllers) {
        if (controller.extendedGamepad != nil) {
            [controllers addObject:controller.vendorName ?: controller.productCategory ?: @"unknown"];
        }
    }
    NSString *screenshot = @"none";
    if (_lastScreenshotMarker != nil) {
        screenshot = [NSString stringWithFormat:@"%.1f-seconds-ago",
            MAX(0.0, -[_lastScreenshotMarker timeIntervalSinceNow])];
    }
    NSString *performance = _lastPerformanceSummary;
    if (performance.length == 0) {
        performance = [NSString stringWithFormat:
            @"fps=%.1f vps=%.1f speedRatio=%.3f efb=%@",
            [_coreHost currentFPS], [_coreHost currentVPS], [_coreHost currentSpeed],
            [_coreHost efbResolution].length > 0 ? [_coreHost efbResolution] : @"unavailable"];
    }
    return [NSString stringWithFormat:
        @"appVersion=%@ build=%@\n"
         @"platform=%@ os=%@\n"
         @"screen=%@ native=%@ drawable=%@\n"
         @"settings renderScale=%ld aspect=%ld experimentalPerformance=%d frameMode=native-60-fps\n"
         @"controllers count=%lu names=%@\n"
         @"recentScreenshot=%@\n"
         @"performance %@\n%@",
        [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown",
        [bundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"unknown",
        UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone",
        NSProcessInfo.processInfo.operatingSystemVersionString,
        NSStringFromCGRect(UIScreen.mainScreen.bounds),
        NSStringFromCGRect(UIScreen.mainScreen.nativeBounds),
        NSStringFromCGSize(((CAMetalLayer *)_gameView.layer).drawableSize),
        (long)settings.renderScale, (long)settings.aspectRatioMode,
        settings.experimentalPerformanceMode,
        (unsigned long)controllers.count,
        controllers.count > 0 ? [controllers componentsJoinedByString:@", "] : @"none",
        screenshot, performance, [_coreHost diagnosticSummary]];
}

- (NSString *)gameOverlayPerformanceProfile:(SsbmPadGameOverlay *)overlay {
    (void)overlay;
    return [_coreHost currentPerformanceProfile];
}

- (GCController *)firstExtendedController {
    GCController *playerOne = [self controllerForPlayerSlot:0];
    if (playerOne != nil)
        return playerOne;
    for (GCController *controller in GCController.controllers) {
        if (controller.extendedGamepad != nil)
            return controller;
    }
    return nil;
}

- (void)presentControllerMapping {
    GCController *controller = [self firstExtendedController];
    SsbmPadControllerButtonMapping mapping = [SsbmPadControllerMappingStore mapping];
    NSString *controllerName = controller.vendorName ?: controller.productCategory;
    NSString *message = controllerName.length > 0
        ? [NSString stringWithFormat:@"Connected: %@\nOnly A, B, X, Y, and Z are remapped. Analog triggers, sticks, D-pad, Start, and the right shoulder spray stay unchanged.",
                                     controllerName]
        : @"No extended controller is connected. You can review or reset the saved mapping; connect a controller to test it.";
    if (controller.physicalInputProfile.hasRemappedElements) {
        message = [message stringByAppendingString:
            @"\n\niOS controller customization is also active, so Apple applies that remap before SsbmPad."];
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Controller Button Mapping"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    const uint16_t gameButtons[] = {
        SsbmPadButtonA, SsbmPadButtonB, SsbmPadButtonX, SsbmPadButtonY, SsbmPadButtonZ,
    };
    __weak SsbmPadGameViewController *weakSelf = self;
    for (uint16_t gameButton : gameButtons) {
        NSString *title = [NSString stringWithFormat:@"%@ — %@",
            SsbmPadGameButtonName(gameButton),
            SsbmPadPhysicalControllerButtonName(
                SsbmPadMappedPhysicalButton(mapping, gameButton))];
        [alert addAction:[UIAlertAction actionWithTitle:title
                                                style:UIAlertActionStyleDefault
                                              handler:^(__kindof UIAlertAction *action) {
            (void)action;
            [weakSelf presentPhysicalButtonChoicesForGameButton:gameButton];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset to Default"
                                            style:UIAlertActionStyleDestructive
                                          handler:^(__kindof UIAlertAction *action) {
        (void)action;
        [SsbmPadControllerMappingStore reset];
        [[SsbmPadInputMixer sharedMixer] clearInputFromTouch:NO];
        SsbmPadLog(@"controller mapping reset to default");
        [weakSelf presentControllerMapping];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentPhysicalButtonChoicesForGameButton:(uint16_t)gameButton {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:SsbmPadGameButtonName(gameButton)
                         message:@"Choose the physical controller button. If it is already assigned, the two assignments swap."
                  preferredStyle:UIAlertControllerStyleAlert];
    const SsbmPadPhysicalControllerButton physicalButtons[] = {
        SsbmPadPhysicalControllerButtonA,
        SsbmPadPhysicalControllerButtonB,
        SsbmPadPhysicalControllerButtonX,
        SsbmPadPhysicalControllerButtonY,
        SsbmPadPhysicalControllerButtonLeftShoulder,
    };
    __weak SsbmPadGameViewController *weakSelf = self;
    for (SsbmPadPhysicalControllerButton physicalButton : physicalButtons) {
        [alert addAction:[UIAlertAction
            actionWithTitle:SsbmPadPhysicalControllerButtonName(physicalButton)
                      style:UIAlertActionStyleDefault
                    handler:^(__kindof UIAlertAction *action) {
            (void)action;
            SsbmPadControllerButtonMapping mapping = [SsbmPadControllerMappingStore mapping];
            mapping = SsbmPadControllerButtonMappingByAssigning(
                mapping, physicalButton, gameButton);
            [SsbmPadControllerMappingStore setMapping:mapping];
            [[SsbmPadInputMixer sharedMixer] clearInputFromTouch:NO];
            SsbmPadLog(@"controller mapping changed game=%@ physical=%@",
                      SsbmPadGameButtonName(gameButton),
                      SsbmPadPhysicalControllerButtonName(physicalButton));
            [weakSelf presentControllerMapping];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                            style:UIAlertActionStyleCancel
                                          handler:^(__kindof UIAlertAction *action) {
        (void)action;
        [weakSelf presentControllerMapping];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentGameDataImport {
    NSArray<UTType *> *types = @[
        [UTType typeWithFilenameExtension:@"iso"],
        [UTType typeWithFilenameExtension:@"gcm"],
        UTTypeData,
    ];
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types
                                                               asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    picker.shouldShowFileExtensions = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (NSArray<NSURL *> *)gameImagesInDocumentsDirectory {
    NSURL *documentsURL = [[[NSFileManager defaultManager]
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    if (documentsURL == nil)
        return @[];

    NSArray<NSURL *> *entries = [[NSFileManager defaultManager]
        contentsOfDirectoryAtURL:documentsURL
      includingPropertiesForKeys:@[NSURLIsRegularFileKey]
                         options:NSDirectoryEnumerationSkipsHiddenFiles
                           error:nil];
    NSMutableArray<NSURL *> *images = [NSMutableArray array];
    NSSet<NSString *> *extensions = [NSSet setWithArray:@[@"iso", @"gcm"]];
    for (NSURL *entry in entries) {
        NSNumber *isRegularFile = nil;
        [entry getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:nil];
        if (isRegularFile.boolValue &&
            [extensions containsObject:entry.pathExtension.lowercaseString]) {
            [images addObject:entry];
        }
    }
    [images sortUsingComparator:^NSComparisonResult(NSURL *left, NSURL *right) {
        return [left.lastPathComponent localizedStandardCompare:right.lastPathComponent];
    }];
    return images;
}

- (void)presentGameDataFolderImport {
    NSArray<NSURL *> *images = [self gameImagesInDocumentsDirectory];
    if (images.count == 1) {
        [self importGameDataFromURL:images.firstObject];
        return;
    }

    NSString *message = images.count == 0
        ? @"No ISO or GCM was found. In Files, place the image directly in On My iPhone → SsbmPad, then try again."
        : @"Choose an image from On My iPhone → SsbmPad.";
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"SsbmPad Folder"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    __weak SsbmPadGameViewController *weakSelf = self;
    for (NSURL *imageURL in images) {
        [alert addAction:[UIAlertAction actionWithTitle:imageURL.lastPathComponent
                                                  style:UIAlertActionStyleDefault
                                                handler:^(__kindof UIAlertAction *action) {
            (void)action;
            [weakSelf importGameDataFromURL:imageURL];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    (void)controller;
    NSURL *url = urls.firstObject;
    if (url == nil)
        return;
    [self importGameDataFromURL:url];
}

- (void)importGameDataFromURL:(NSURL *)url {
    UIAlertController *progressAlert =
        [UIAlertController alertControllerWithTitle:@"Importing Game Data"
                                            message:@"Validating and copying the disc…"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:progressAlert animated:YES completion:nil];

    NSString *supportRoot = [self sunPadSupportRoot];
    NSString *stagingDirectory = [supportRoot stringByAppendingPathComponent:
        [NSString stringWithFormat:@"GameData.import-%@", NSUUID.UUID.UUIDString]];
    NSString *stagedImage = [stagingDirectory stringByAppendingPathComponent:@"GALE01.iso"];
    NSString *stagedRoot = [stagingDirectory stringByAppendingPathComponent:@"GALE01"];
    __weak SsbmPadGameViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray<NSString *> *supportEntries = [[NSFileManager defaultManager]
            contentsOfDirectoryAtPath:supportRoot error:nil];
        for (NSString *entry in supportEntries) {
            if ([entry hasPrefix:@"GameData.import-"] &&
                ![[supportRoot stringByAppendingPathComponent:entry]
                    isEqualToString:stagingDirectory]) {
                [[NSFileManager defaultManager]
                    removeItemAtPath:[supportRoot stringByAppendingPathComponent:entry]
                              error:nil];
            }
        }

        BOOL securityScoped = [url startAccessingSecurityScopedResource];
        NSString *validationError = [weakSelf validateGameDataAtURL:url];
        NSError *copyError = nil;
        if (validationError == nil) {
            [[NSFileManager defaultManager] createDirectoryAtPath:stagingDirectory
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&copyError];
        }
        if (validationError == nil && copyError == nil) {
            [[NSFileManager defaultManager] copyItemAtURL:url
                                                    toURL:[NSURL fileURLWithPath:stagedImage]
                                                    error:&copyError];
        }
        if (validationError == nil && copyError == nil) {
            NSString *hash = SsbmPadSHA256ForFile(stagedImage, &copyError);
            if (copyError == nil && ![hash isEqualToString:SsbmPadSupportedImageSHA256])
                validationError = @"The image SHA-256 does not match supported GALE01 USA revision 0 data.";
        }
        if (securityScoped)
            [url stopAccessingSecurityScopedResource];

        dispatch_async(dispatch_get_main_queue(), ^{
            SsbmPadGameViewController *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            if (validationError != nil || copyError != nil) {
                [[NSFileManager defaultManager] removeItemAtPath:stagingDirectory error:nil];
                [progressAlert dismissViewControllerAnimated:YES completion:^{
                    [strongSelf presentBootError:validationError ?: [NSString stringWithFormat:
                        @"Could not retain the game image: %@", copyError.localizedDescription]];
                }];
                return;
            }

            progressAlert.message = @"Extracting the disc…";
            [SsbmPadDiscExtractor extractImageAtPath:stagedImage
                                       toDirectory:stagedRoot
                                           progress:^(NSString *status, double fraction) {
                progressAlert.message = [NSString stringWithFormat:@"%@ (%.0f%%)",
                                         status, fraction * 100.0];
            }
                                         completion:^(BOOL ok, NSString *error) {
                SsbmPadGameViewController *completedSelf = weakSelf;
                if (completedSelf == nil)
                    return;
                if (!ok) {
                    [[NSFileManager defaultManager] removeItemAtPath:stagingDirectory error:nil];
                    [progressAlert dismissViewControllerAnimated:YES completion:^{
                        [completedSelf presentBootError:error ?: @"Extraction failed."];
                    }];
                    return;
                }

                NSArray<NSString *> *required = @[
                    @"sys/boot.bin", @"sys/bi2.bin", @"sys/apploader.img",
                    @"sys/fst.bin", @"sys/main.dol", @"files/opening.bnr",
                    @"files/AudioRes/mSound.asn", @"files/data/common.szs",
                ];
                for (NSString *relative in required) {
                    if (![[NSFileManager defaultManager] fileExistsAtPath:
                          [stagedRoot stringByAppendingPathComponent:relative]]) {
                        [[NSFileManager defaultManager] removeItemAtPath:stagingDirectory error:nil];
                        [progressAlert dismissViewControllerAnimated:YES completion:^{
                            [completedSelf presentBootError:@"The extracted game data is incomplete."];
                        }];
                        return;
                    }
                }
                if (SsbmPadRegularFileCount([stagedRoot stringByAppendingPathComponent:@"files"]) != 174) {
                    [[NSFileManager defaultManager] removeItemAtPath:stagingDirectory error:nil];
                    [progressAlert dismissViewControllerAnimated:YES completion:^{
                        [completedSelf presentBootError:@"The extracted game file count is incomplete."];
                    }];
                    return;
                }

                if (completedSelf->_coreHost != nil) {
                    [completedSelf->_coreHost stop];
                    completedSelf->_coreHost = nil;
                }
                NSString *dataDirectory = [supportRoot stringByAppendingPathComponent:@"GameData"];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *swapError = nil;
                if ([fileManager fileExistsAtPath:dataDirectory]) {
                    NSURL *resultURL = nil;
                    [fileManager replaceItemAtURL:[NSURL fileURLWithPath:dataDirectory]
                                    withItemAtURL:[NSURL fileURLWithPath:stagingDirectory]
                                   backupItemName:nil options:0
                                 resultingItemURL:&resultURL error:&swapError];
                } else {
                    [fileManager moveItemAtPath:stagingDirectory
                                         toPath:dataDirectory error:&swapError];
                }
                if (swapError != nil) {
                    [completedSelf startGameIfProvisioned];
                    [progressAlert dismissViewControllerAnimated:YES completion:^{
                        [completedSelf presentBootError:[NSString stringWithFormat:
                            @"Could not activate the imported game data: %@",
                            swapError.localizedDescription]];
                    }];
                    return;
                }

                NSString *destination = [dataDirectory stringByAppendingPathComponent:@"GALE01.iso"];
                NSString *extractRoot = [dataDirectory stringByAppendingPathComponent:@"GALE01"];
                SsbmPadSettings *settings = [SsbmPadSettings sharedSettings];
                settings.retainedGameDataPath = destination;
                settings.extractedGameRoot = extractRoot;
                [settings synchronize];
                SsbmPadLog(@"game data import activated filename=%@", destination.lastPathComponent);
                [progressAlert dismissViewControllerAnimated:YES completion:^{
                    [completedSelf startGameIfProvisioned];
                }];
            }];
        });
    });
}

- (nullable NSString *)validateGameDataAtURL:(NSURL *)url {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:url.path];
    if (handle == nil)
        return @"The selected file could not be opened.";
    NSData *header = [handle readDataOfLength:0x100];
    [handle closeFile];
    if (header.length < 0x100)
        return @"The file is too small to be a GameCube image.";

    NSNumber *fileSize = [[[NSFileManager defaultManager]
        attributesOfItemAtPath:url.path error:nil] objectForKey:NSFileSize];
    if (fileSize.unsignedLongLongValue != 1459978240ULL)
        return @"The image size does not match the supported GALE01 USA revision 0 disc.";

    const uint8_t *bytes = (const uint8_t *)header.bytes;
    uint32_t magic = CFSwapInt32BigToHost(*(uint32_t *)(bytes + 0x1C));
    if (magic != 0xC2339F3D)
        return @"The file is not a GameCube disc image (bad magic).";
    char gameId[7] = {0};
    // The GameCube disc header starts with the six-character game code.
    memcpy(gameId, bytes + 0x00, 6);
    if (strncmp(gameId, "GALE01", 6) != 0)
        return [NSString stringWithFormat:@"Unsupported game ID '%s'; SsbmPad currently supports GALE01 (Super Smash Bros. Melee USA).", gameId];
    if (bytes[6] != 0 || bytes[7] != 0)
        return @"SsbmPad currently supports disc 0, revision 0 only.";
    return nil;
}

- (NSString *)sunPadSupportRoot {
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support"]
        stringByAppendingPathComponent:@"SsbmPad"];
}

@end
