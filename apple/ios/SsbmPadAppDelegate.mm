#import <UIKit/UIKit.h>
#import <os/proc.h>

#import "SsbmPadDiagnostics.h"
#import "SsbmPadGameViewController.h"

@interface SsbmPadAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic) UIBackgroundTaskIdentifier saveFlushTask;
- (void)beginSaveFlushGraceForApplication:(UIApplication *)application;
- (void)endSaveFlushGraceForApplication:(UIApplication *)application reason:(NSString *)reason;
@end

static void SsbmPadRestorePreferencesIfRequested(void) {
    NSArray<NSString *> *arguments = NSProcessInfo.processInfo.arguments;
    if (![arguments containsObject:@"-ssbmpadRestorePreferences"])
        return;

    NSString *restorePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"tmp"]
        stringByAppendingPathComponent:@"SsbmPadPreferencesRestore.plist"];
    NSDictionary *restored = [NSDictionary dictionaryWithContentsOfFile:restorePath];
    if (restored.count == 0) {
        SsbmPadLog(@"preferences restore skipped path=%@ reason=missing or empty", restorePath);
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    for (NSString *key in restored)
        [defaults setObject:restored[key] forKey:key];
    [defaults synchronize];
    [[NSFileManager defaultManager] removeItemAtPath:restorePath error:nil];
    SsbmPadLog(@"preferences restored keys=%lu", (unsigned long)restored.count);
}

@implementation SsbmPadAppDelegate

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

    SsbmPadDiagnosticsStart();
    SsbmPadRestorePreferencesIfRequested();
    self.saveFlushTask = UIBackgroundTaskInvalid;
    UIScreen *screen = UIScreen.mainScreen;
    SsbmPadLog(@"launch screen bounds=%@ nativeBounds=%@ scale=%.2f nativeScale=%.2f maxFPS=%ld",
              NSStringFromCGRect(screen.bounds), NSStringFromCGRect(screen.nativeBounds),
              screen.scale, screen.nativeScale, (long)screen.maximumFramesPerSecond);

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    SsbmPadGameViewController *root = [[SsbmPadGameViewController alloc] init];
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    SsbmPadLog(@"lifecycle didBecomeActive");
    [self endSaveFlushGraceForApplication:application reason:@"active"];
    [(SsbmPadGameViewController *)self.window.rootViewController
        resumeRuntimeForApplicationLifecycle];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    SsbmPadLog(@"lifecycle willResignActive");
    [(SsbmPadGameViewController *)self.window.rootViewController
        pauseRuntimeForApplicationLifecycle];
    [self beginSaveFlushGraceForApplication:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    (void)application;
    SsbmPadLog(@"lifecycle didEnterBackground");
}

- (void)beginSaveFlushGraceForApplication:(UIApplication *)application {
    // Dolphin's GCI-folder backend flushes one second after writes stop. The
    // runtime was paused in applicationWillResignActive, so keep the process
    // alive briefly enough for that existing save thread to finish without
    // forcing a shutdown or reaching into its private memory-card state.
    __block UIBackgroundTaskIdentifier task = UIBackgroundTaskInvalid;
    __weak SsbmPadAppDelegate *weakSelf = self;
    task = [application beginBackgroundTaskWithName:@"SsbmPad save flush grace"
                                  expirationHandler:^{
        SsbmPadAppDelegate *strongSelf = weakSelf;
        if (strongSelf.saveFlushTask == task)
            [strongSelf endSaveFlushGraceForApplication:application reason:@"expired"];
    }];
    if (task == UIBackgroundTaskInvalid) {
        SsbmPadLog(@"lifecycle save flush grace unavailable");
        return;
    }

    if (self.saveFlushTask != UIBackgroundTaskInvalid)
        [self endSaveFlushGraceForApplication:application reason:@"replaced"];
    self.saveFlushTask = task;
    SsbmPadLog(@"lifecycle save flush grace started");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        SsbmPadAppDelegate *strongSelf = weakSelf;
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
    SsbmPadLog(@"lifecycle save flush grace ended reason=%@", reason);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    (void)application;
    SsbmPadLog(@"lifecycle willEnterForeground");
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    (void)application;
    SsbmPadLog(@"memory warning physical=%llu available=%llu",
              (unsigned long long)NSProcessInfo.processInfo.physicalMemory,
              (unsigned long long)os_proc_available_memory());
}

- (void)applicationWillTerminate:(UIApplication *)application {
    (void)application;
    SsbmPadLog(@"lifecycle willTerminate");
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SsbmPadAppDelegate class]));
    }
}
