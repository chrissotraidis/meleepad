// Private offline diagnostic host. Never imports the installed app's container.
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <cstdio>
#include <unistd.h>

int SlippiProbeMain(int argc, char** argv, void* render_surface);

@interface SlippiProbeSurface : UIView
@end
@implementation SlippiProbeSurface
+ (Class)layerClass { return CAMetalLayer.class; }
@end

@interface SlippiProbeController : UIViewController
@property(nonatomic, strong) SlippiProbeSurface* surface;
@property(nonatomic, strong) UIButton* runButton;
@property(nonatomic, strong) UILabel* status;
@property(nonatomic) BOOL started;
@end

@implementation SlippiProbeController
- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.blackColor;
  self.surface = [[SlippiProbeSurface alloc] initWithFrame:self.view.bounds];
  self.surface.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  CAMetalLayer* layer = (CAMetalLayer*)self.surface.layer;
  layer.device = MTLCreateSystemDefaultDevice();
  layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  [self.view addSubview:self.surface];
  self.status = [[UILabel alloc] init];
  self.status.text = @"Slippi offline probe — no online play";
  self.status.textColor = UIColor.whiteColor;
  self.status.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
  self.status.textAlignment = NSTextAlignmentCenter;
  self.status.numberOfLines = 2;
  self.status.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.status];
  self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.runButton setTitle:@"Run offline test" forState:UIControlStateNormal];
  self.runButton.backgroundColor = UIColor.systemBackgroundColor;
  self.runButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.runButton addTarget:self action:@selector(runProbe) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.runButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.status.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
    [self.status.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
    [self.status.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [self.status.heightAnchor constraintEqualToConstant:48],
    [self.runButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.runButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [self.runButton.widthAnchor constraintEqualToConstant:220],
    [self.runButton.heightAnchor constraintEqualToConstant:60]
  ]];
}
- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // Native GameCube render target; avoids conflating retina scaling with runtime speed.
  ((CAMetalLayer*)self.surface.layer).drawableSize = CGSizeMake(640, 480);
}
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if ([NSProcessInfo.processInfo.arguments containsObject:@"-runOfflineProbe"])
    [self runProbe];
}
- (void)runProbe {
  if (self.started) return;
  self.started = YES;
  self.runButton.hidden = YES;
  self.status.text = @"Running offline test…";
  UIApplication.sharedApplication.idleTimerDisabled = YES;
  NSString* bundle = NSBundle.mainBundle.bundlePath;
  NSString* documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
  NSString* run = [documents stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
  NSError* error = nil;
  if (![NSFileManager.defaultManager createDirectoryAtPath:run withIntermediateDirectories:YES attributes:nil error:&error]) {
    self.status.text = @"Could not create diagnostic directory.";
    UIApplication.sharedApplication.idleTimerDisabled = NO;
    return;
  }
  CAMetalLayer* layer = (CAMetalLayer*)self.surface.layer;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    @autoreleasepool {
      NSString* log = [run stringByAppendingPathComponent:@"runtime.log"];
      if (!freopen(log.fileSystemRepresentation, "w", stdout) || dup2(fileno(stdout), fileno(stderr)) < 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
          UIApplication.sharedApplication.idleTimerDisabled = NO;
          self.status.text = @"Could not open diagnostic log.";
        });
        return;
      }
      setvbuf(stdout, nullptr, _IOLBF, 0);
      setvbuf(stderr, nullptr, _IOLBF, 0);
      setenv("SLIPPI_PROBE_GRAPHICS", "Metal", 1);
      setenv("SLIPPI_PROBE_GROUPS", "required", 1);
      setenv("SLIPPI_PROBE_SECONDS", "60", 1);
      setenv("SLIPPI_PROBE_SCREENSHOT", "1", 1);
      setenv("SLIPPI_PROBE_INPUT_SCRIPT", [bundle stringByAppendingPathComponent:@"match-start-input.txt"].fileSystemRepresentation, 1);
      NSString* game = [bundle stringByAppendingPathComponent:@"ProbeGame"];
      NSString* iso = [bundle stringByAppendingPathComponent:@"Probe.iso"];
      NSString* module = [bundle stringByAppendingPathComponent:@"Frameworks/gGALE01_recomp.dylib"];
      NSString* user = [run stringByAppendingPathComponent:@"User"];
      const char* values[] = {"SlippiProbe", game.fileSystemRepresentation, iso.fileSystemRepresentation,
                              module.fileSystemRepresentation, user.fileSystemRepresentation};
      char* arguments[5];
      for (int i = 0; i < 5; ++i) arguments[i] = const_cast<char*>(values[i]);
      NSInteger initialThermal = NSProcessInfo.processInfo.thermalState;
      double start = NSProcessInfo.processInfo.systemUptime;
      int result = SlippiProbeMain(5, arguments, (__bridge void*)layer);
      NSDictionary* report = @{@"exit_code": @(result), @"elapsed_seconds": @(NSProcessInfo.processInfo.systemUptime - start),
                              @"initial_thermal_state": @(initialThermal),
                              @"final_thermal_state": @(NSProcessInfo.processInfo.thermalState),
                              @"online_tested": @NO, @"audio_tested": @NO};
      NSData* json = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];
      [json writeToFile:[run stringByAppendingPathComponent:@"device-result.json"] atomically:YES];
      fflush(stdout); fflush(stderr);
      dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication.sharedApplication.idleTimerDisabled = NO;
        self.status.text = result == 0 ? @"Offline test passed. Online play remains untested." :
                                        [NSString stringWithFormat:@"Offline test stopped (code %d). Diagnostics saved.", result];
      });
    }
  });
}
@end

@interface SlippiProbeApp : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow* window;
@end
@implementation SlippiProbeApp
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)options {
  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  self.window.rootViewController = [SlippiProbeController new];
  [self.window makeKeyAndVisible];
  return YES;
}
@end

int main(int argc, char** argv) {
  @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(SlippiProbeApp.class)); }
}
