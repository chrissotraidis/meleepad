#import <UIKit/UIKit.h>
#import <os/proc.h>

#import "MeleePadDiagnostics.h"
#import "MeleePadGameViewController.h"

@interface MeleePadAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic) UIBackgroundTaskIdentifier saveFlushTask;
- (void)beginSaveFlushGraceForApplication:(UIApplication *)application;
- (void)endSaveFlushGraceForApplication:(UIApplication *)application reason:(NSString *)reason;
@end

// Apps built with the iOS 27 SDK must start through UIKit scenes. The single
// application scene (Info.plist) owns the window and forwards its lifecycle to the
// app delegate's existing handlers, which UIKit no longer calls for scene apps.
@interface MeleePadSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

static void MeleePadRestorePreferencesIfRequested(void) {
    NSArray<NSString *> *arguments = NSProcessInfo.processInfo.arguments;
    if (![arguments containsObject:@"-meleepadRestorePreferences"])
        return;

    NSString *restorePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"tmp"]
        stringByAppendingPathComponent:@"MeleePadPreferencesRestore.plist"];
    NSDictionary *restored = [NSDictionary dictionaryWithContentsOfFile:restorePath];
    if (restored.count == 0) {
        MeleePadLog(@"preferences restore skipped path=%@ reason=missing or empty", restorePath);
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    for (NSString *key in restored)
        [defaults setObject:restored[key] forKey:key];
    [defaults synchronize];
    [[NSFileManager defaultManager] removeItemAtPath:restorePath error:nil];
    MeleePadLog(@"preferences restored keys=%lu", (unsigned long)restored.count);
}

static void MeleePadMigrateRenamedPreferences(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDictionary<NSString *, id> *stored = defaults.dictionaryRepresentation;
    NSArray<NSString *> *suffixes = @[
        @"RenderScale", @"AspectRatioMode", @"ShowFPSCounter",
        @"HideControlsOnController", @"ModernCStickHorizontal",
        @"RightStickSmashAttacks", @"UnlockAllCharactersAndStages",
        @"CStickBattleDefaultV2",
        @"ControlOpacity", @"ControlSizeScale",
        @"EditingControlLayout", @"ControlSizeScales", @"ControlOrigins",
        @"ExperimentalDPadOrigin", @"ExperimentalDPadScale",
        @"ExperimentalTouchControls", @"RetainedGameDataPath",
        @"ExtractedGameRoot", @"DeviceBundledSaveSeedID",
        @"ControllerButtonMappingV1",
    ];

    NSUInteger migrated = 0;
    for (NSString *suffix in suffixes) {
        NSString *currentKey = [@"MeleePad" stringByAppendingString:suffix];
        if ([defaults objectForKey:currentKey] != nil)
            continue;

        NSMutableArray<NSString *> *candidates = [NSMutableArray array];
        for (NSString *storedKey in stored) {
            if (![storedKey isEqualToString:currentKey] &&
                [storedKey hasSuffix:suffix]) {
                [candidates addObject:storedKey];
            }
        }
        if (candidates.count == 1) {
            [defaults setObject:stored[candidates.firstObject] forKey:currentKey];
            ++migrated;
        }
    }
    if (migrated > 0) {
        [defaults synchronize];
        MeleePadLog(@"preferences migrated to current product keys count=%lu",
                    (unsigned long)migrated);
    }
}

@implementation MeleePadAppDelegate

- (UIInterfaceOrientationMask)application:(UIApplication *)application
    supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    (void)application;
    (void)window;
    // Super Smash Bros. Melee is a landscape-only experience.
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    MeleePadDiagnosticsStart();
    MeleePadRestorePreferencesIfRequested();
    MeleePadMigrateRenamedPreferences();
    self.saveFlushTask = UIBackgroundTaskInvalid;
    UIScreen *screen = UIScreen.mainScreen;
    MeleePadLog(@"launch screen bounds=%@ nativeBounds=%@ scale=%.2f nativeScale=%.2f maxFPS=%ld",
              NSStringFromCGRect(screen.bounds), NSStringFromCGRect(screen.nativeBounds),
              screen.scale, screen.nativeScale, (long)screen.maximumFramesPerSecond);

    // The window is created when UIKit connects the application scene.
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    MeleePadLog(@"lifecycle didBecomeActive");
    [self endSaveFlushGraceForApplication:application reason:@"active"];
    [(MeleePadGameViewController *)self.window.rootViewController
        resumeRuntimeForApplicationLifecycle];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    MeleePadLog(@"lifecycle willResignActive");
    [(MeleePadGameViewController *)self.window.rootViewController
        pauseRuntimeForApplicationLifecycle];
    [self beginSaveFlushGraceForApplication:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    (void)application;
    MeleePadLog(@"lifecycle didEnterBackground");
}

- (void)beginSaveFlushGraceForApplication:(UIApplication *)application {
    // Dolphin's GCI-folder backend flushes one second after writes stop. The
    // runtime was paused in applicationWillResignActive, so keep the process
    // alive briefly enough for that existing save thread to finish without
    // forcing a shutdown or reaching into its private memory-card state.
    __block UIBackgroundTaskIdentifier task = UIBackgroundTaskInvalid;
    __weak MeleePadAppDelegate *weakSelf = self;
    task = [application beginBackgroundTaskWithName:@"MeleePad save flush grace"
                                  expirationHandler:^{
        MeleePadAppDelegate *strongSelf = weakSelf;
        if (strongSelf.saveFlushTask == task)
            [strongSelf endSaveFlushGraceForApplication:application reason:@"expired"];
    }];
    if (task == UIBackgroundTaskInvalid) {
        MeleePadLog(@"lifecycle save flush grace unavailable");
        return;
    }

    if (self.saveFlushTask != UIBackgroundTaskInvalid)
        [self endSaveFlushGraceForApplication:application reason:@"replaced"];
    self.saveFlushTask = task;
    MeleePadLog(@"lifecycle save flush grace started");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        MeleePadAppDelegate *strongSelf = weakSelf;
        if (strongSelf.saveFlushTask == task)
            [strongSelf endSaveFlushGraceForApplication:application reason:@"timer"];
    });
}

- (void)endSaveFlushGraceForApplication:(UIApplication *)application reason:(NSString *)reason {
    UIBackgroundTaskIdentifier task = self.saveFlushTask;
    if (task == UIBackgroundTaskInvalid)
        return;
    self.saveFlushTask = UIBackgroundTaskInvalid;
    [application endBackgroundTask:task];
    MeleePadLog(@"lifecycle save flush grace ended reason=%@", reason);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    (void)application;
    MeleePadLog(@"lifecycle willEnterForeground");
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    (void)application;
    MeleePadLog(@"memory warning physical=%llu available=%llu",
              (unsigned long long)NSProcessInfo.processInfo.physicalMemory,
              (unsigned long long)os_proc_available_memory());
}

- (void)applicationWillTerminate:(UIApplication *)application {
    (void)application;
    MeleePadLog(@"lifecycle willTerminate");
}

@end

@implementation MeleePadSceneDelegate

- (MeleePadAppDelegate *)appDelegate {
    return (MeleePadAppDelegate *)UIApplication.sharedApplication.delegate;
}

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    (void)session;
    (void)connectionOptions;
    if (![scene isKindOfClass:UIWindowScene.class] || self.window != nil)
        return;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = [[MeleePadGameViewController alloc] init];
    // Existing code reaches the game through the app delegate's window.
    self.appDelegate.window = self.window;
    [self.window makeKeyAndVisible];
    MeleePadLog(@"lifecycle scene connected bounds=%@",
              NSStringFromCGRect(((UIWindowScene *)scene).coordinateSpace.bounds));
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    (void)scene;
    [self.appDelegate applicationDidBecomeActive:UIApplication.sharedApplication];
}

- (void)sceneWillResignActive:(UIScene *)scene {
    (void)scene;
    [self.appDelegate applicationWillResignActive:UIApplication.sharedApplication];
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    (void)scene;
    [self.appDelegate applicationWillEnterForeground:UIApplication.sharedApplication];
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    (void)scene;
    [self.appDelegate applicationDidEnterBackground:UIApplication.sharedApplication];
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([MeleePadAppDelegate class]));
    }
}
