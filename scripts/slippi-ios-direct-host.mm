// Separate private Direct acceptance UI; never reads the MeleePad container.
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <GameController/GameController.h>
#import <Security/Security.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <AVFAudio/AVFAudio.h>
#include "slippi-direct-probe.hpp"
#include "slippi-probe-account.hpp"
#include <cstdio>
#include <unistd.h>

static NSMutableDictionary* AccountQuery() {
  return [@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:@"com.meleepad.SlippiProbe.direct-account",
            (__bridge id)kSecAttrAccount:@"explicit-import",
            (__bridge id)kSecAttrSynchronizable:@NO} mutableCopy];
}
static NSData* ReadAccount() {
  NSMutableDictionary* query=AccountQuery();
  query[(__bridge id)kSecReturnData]=@YES;
  CFTypeRef result=nullptr;
  if (SecItemCopyMatching((__bridge CFDictionaryRef)query,&result)!=errSecSuccess) return nil;
  return CFBridgingRelease(result);
}
@interface DirectSurface:UIView @end
@implementation DirectSurface
+(Class)layerClass { return CAMetalLayer.class; }
@end
@interface DirectController:UIViewController<UIDocumentPickerDelegate>
@property UILabel* status;
@property UIStackView* controls;
@property UIButton* startButton;
@property UIButton* importButton;
@property UIButton* forgetButton;
@property NSTimer* timer;
@property BOOL started;
@property BOOL wiredImportAttempted;
@property DirectSurface* surface;
@end
@implementation DirectController
-(UIButton*)button:(NSString*)title action:(SEL)action {
  UIButton* button=[UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  button.backgroundColor=UIColor.secondarySystemBackgroundColor;
  [button.heightAnchor constraintEqualToConstant:48].active=YES;
  return button;
}
-(void)viewDidLoad {
  [super viewDidLoad]; self.view.backgroundColor=UIColor.blackColor;
  self.surface=[[DirectSurface alloc]initWithFrame:self.view.bounds];
  self.surface.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  CAMetalLayer* layer=(CAMetalLayer*)self.surface.layer;
  layer.device=MTLCreateSystemDefaultDevice(); layer.pixelFormat=MTLPixelFormatBGRA8Unorm;
  [self.view addSubview:self.surface];
  self.status=[UILabel new]; self.status.textColor=UIColor.whiteColor;
  self.status.numberOfLines=3; self.status.textAlignment=NSTextAlignmentCenter;
  self.status.text=@"Experimental Slippi Direct\nImport your own account file and connect a controller.\nDesktop crossplay is not yet verified.";
  self.status.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:0.8];
  self.importButton=[self button:@"Import Slippi account" action:@selector(importAccount)];
  self.startButton=[self button:@"Start Direct test" action:@selector(startTest)];
  self.forgetButton=[self button:@"Forget imported account" action:@selector(forgetAccount)];
  UIButton* stop=[self button:@"Stop test" action:@selector(stopTest)];
  self.controls=[[UIStackView alloc]initWithArrangedSubviews:@[self.status,self.importButton,self.startButton,self.forgetButton,stop]];
  self.controls.axis=UILayoutConstraintAxisVertical; self.controls.spacing=8;
  self.controls.translatesAutoresizingMaskIntoConstraints=NO;
  [self.view addSubview:self.controls];
  [NSLayoutConstraint activateConstraints:@[
    [self.controls.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
    [self.controls.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.controls.widthAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.widthAnchor multiplier:0.8]]];
  // Delete only this target's abandoned plaintext handoffs after an interrupted
  // run. No user-supplied export, Keychain item, game or save is removed here.
  NSString* root=[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"DirectRuns"];
  for (NSString* name in [NSFileManager.defaultManager contentsOfDirectoryAtPath:root error:nil]) {
    if ([[NSUUID alloc]initWithUUIDString:name])
      [NSFileManager.defaultManager removeItemAtPath:[root stringByAppendingPathComponent:[name stringByAppendingPathComponent:@"User/Slippi/user.json"]] error:nil];
  }
  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(stopTest) name:UIApplicationWillResignActiveNotification object:nil];
  self.timer=[NSTimer scheduledTimerWithTimeInterval:1.0/120 target:self selector:@selector(pollController) userInfo:nil repeats:YES];
}
-(void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; ((CAMetalLayer*)self.surface.layer).drawableSize=CGSizeMake(640,480); }
-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (self.wiredImportAttempted) return;
  self.wiredImportAttempted=YES;
  NSArray* arguments=NSProcessInfo.processInfo.arguments;
  if ([arguments containsObject:@"-importWiredAccount"]) {
    NSString* path=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"slippi-account-import.json"];
    NSData* data=[NSData dataWithContentsOfFile:path];
    BOOL stored=[self storeAccount:data];
    if (stored) [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    NSDictionary* result=@{@"keychain_stored":@(stored),@"keychain_readback_matches":@(stored && [ReadAccount() isEqualToData:[self normalizedAccount:data]]),
      @"inbound_copy_removed":@(![NSFileManager.defaultManager fileExistsAtPath:path]),@"service_authenticated":@NO};
    NSString* report=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"direct-account-import-result.json"];
    [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil]writeToFile:report atomically:YES];
    if (!stored) return;
  }
  if ([arguments containsObject:@"-runAccountBootCheck"] && ReadAccount()) {
    SlippiDirectProbe::account_boot_check=true;
    [self startTest];
  }
}
-(void)pollController {
  GCExtendedGamepad* g=nil;
  for (GCController* c in GCController.controllers) if (c.extendedGamepad) { g=c.extendedGamepad; break; }
  SlippiDirectProbe::Pad pad;
  if (g && UIApplication.sharedApplication.applicationState==UIApplicationStateActive) {
    pad.x=g.leftThumbstick.xAxis.value; pad.y=g.leftThumbstick.yAxis.value;
    // D-pad also navigates the game's menus without analog movement.
    if (pad.x==0) pad.x=g.dpad.xAxis.value;
    if (pad.y==0) pad.y=g.dpad.yAxis.value;
    pad.cx=g.rightThumbstick.xAxis.value; pad.cy=g.rightThumbstick.yAxis.value;
    pad.l=g.leftTrigger.value; pad.r=g.rightTrigger.value;
    pad.buttons=(g.buttonA.pressed?1u:0u)|(g.buttonB.pressed?2u:0u)|(g.buttonX.pressed?4u:0u)|
      (g.buttonY.pressed?8u:0u)|(g.rightShoulder.pressed?16u:0u)|(g.buttonMenu.pressed?32u:0u);
  }
  { std::lock_guard lock(SlippiDirectProbe::pad_mutex); SlippiDirectProbe::pad=pad; }
  if (!self.started) self.startButton.enabled=g!=nil;
}
-(void)importAccount {
  if (self.started) return;
  UIDocumentPickerViewController* picker=[[UIDocumentPickerViewController alloc]initForOpeningContentTypes:@[UTTypeJSON] asCopy:NO];
  picker.delegate=self; picker.allowsMultipleSelection=NO;
  [self presentViewController:picker animated:YES completion:nil];
}
-(void)documentPicker:(UIDocumentPickerViewController*)picker didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
  NSURL* url=urls.firstObject; if (!url || self.started) return;
  BOOL access=[url startAccessingSecurityScopedResource];
  NSNumber* size=nil; NSNumber* regular=nil;
  [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
  [url getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
  NSData* data=regular.boolValue && size.unsignedLongLongValue>0 && size.unsignedLongLongValue<=16384 ? [NSData dataWithContentsOfURL:url] : nil;
  if (access) [url stopAccessingSecurityScopedResource];
  [self storeAccount:data];
}
-(NSData*)normalizedAccount:(NSData*)data {
  std::string clean;
  if (!data || !SlippiProbeAccount::Normalize(std::string((const char*)data.bytes,data.length),clean)) {
    return nil;
  }
  return [NSData dataWithBytes:clean.data() length:clean.size()];
}
-(BOOL)storeAccount:(NSData*)data {
  NSData* normalized=[self normalizedAccount:data];
  if (!normalized) { self.status.text=@"Account file was not accepted. Select your own Slippi user.json export."; return NO; }
  NSMutableDictionary* values=[@{(__bridge id)kSecValueData:normalized,
    (__bridge id)kSecAttrAccessible:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly} mutableCopy];
  OSStatus result=SecItemUpdate((__bridge CFDictionaryRef)AccountQuery(),(__bridge CFDictionaryRef)values);
  if (result==errSecItemNotFound) {
    [values addEntriesFromDictionary:AccountQuery()]; result=SecItemAdd((__bridge CFDictionaryRef)values,nullptr);
  }
  self.status.text=result==errSecSuccess ? @"Account imported to this device's Keychain.\nService authentication has not been tested.\nUse Direct with an arranged opponent." : @"Could not store the account in Keychain.";
  return result==errSecSuccess;
}
-(void)forgetAccount {
  if (self.started) return;
  OSStatus status=SecItemDelete((__bridge CFDictionaryRef)AccountQuery());
  self.status.text=(status==errSecSuccess || status==errSecItemNotFound) ? @"Imported account removed from this device." : @"Could not remove the imported account.";
}
-(void)stopTest { if (self.started) { SlippiDirectProbe::stop=true; self.status.text=@"Stopping test…"; } }
-(void)startTest {
  if (self.started) return;
  NSData* account=ReadAccount();
  if (!account) { self.status.text=@"Import your own Slippi account file first."; return; }
  if (!self.startButton.enabled && !SlippiDirectProbe::account_boot_check) return;
  self.started=YES; self.startButton.hidden=YES; self.importButton.hidden=YES; self.forgetButton.hidden=YES;
  self.status.text=@"Direct only. Select your arranged opponent in the game's menu.\nExperimental client; required game-code subset.";
  UIApplication.sharedApplication.idleTimerDisabled=YES;
  NSString* root=[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"DirectRuns"];
  NSString* run=[root stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
  NSError* error=nil;
  BOOL made=[NSFileManager.defaultManager createDirectoryAtPath:run withIntermediateDirectories:YES
    attributes:@{NSFileProtectionKey:NSFileProtectionComplete,NSFilePosixPermissions:@0700} error:&error];
  if (!made) { self.status.text=@"Could not create a private test directory. Reopen to retry."; UIApplication.sharedApplication.idleTimerDisabled=NO; return; }
  [[NSURL fileURLWithPath:root]setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
  NSString* bundle=NSBundle.mainBundle.bundlePath;
  CAMetalLayer* surface=(CAMetalLayer*)self.surface.layer;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
    @autoreleasepool {
      // Keep raw runtime output out of diagnostic exports. Structured counters
      // and traces are written separately; traces themselves remain private.
      freopen("/dev/null","w",stdout); dup2(fileno(stdout),fileno(stderr));
      NSError* audioError=nil;
      AVAudioSession* audio=AVAudioSession.sharedInstance;
      BOOL audioOK=[audio setCategory:AVAudioSessionCategoryPlayback error:&audioError] && [audio setActive:YES error:&audioError];
      double start=NSProcessInfo.processInfo.systemUptime;
      int result=audioOK ? SlippiDirectMain([bundle stringByAppendingPathComponent:@"ProbeGame"].fileSystemRepresentation,
        [bundle stringByAppendingPathComponent:@"Probe.iso"].fileSystemRepresentation,
        [bundle stringByAppendingPathComponent:@"Frameworks/gGALE01_recomp.dylib"].fileSystemRepresentation,
        [run stringByAppendingPathComponent:@"User"].fileSystemRepresentation,
        std::string((const char*)account.bytes,account.length),(__bridge void*)surface) : 17;
      NSDictionary* report=@{@"exit_code":@(result),@"elapsed_seconds":@(NSProcessInfo.processInfo.systemUptime-start),
        @"crossplay_accepted":@NO,@"audio_session_active":@(audioOK),@"manual_input":@YES};
      [[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil]
        writeToFile:[run stringByAppendingPathComponent:@"device-result.json"] atomically:YES];
      [audio setActive:NO error:nil];
      dispatch_async(dispatch_get_main_queue(),^{
        UIApplication.sharedApplication.idleTimerDisabled=NO;
        self.status.text=[NSString stringWithFormat:@"Test stopped (code %d). Crossplay needs review.\nReopen the probe for another run or to remove the account.",result];
      });
    }
  });
}
@end
@interface DirectApp:UIResponder<UIApplicationDelegate> @property(nonatomic,strong) UIWindow* window; @end
@implementation DirectApp
-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)options {
  self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds]; self.window.rootViewController=[DirectController new];
  [self.window makeKeyAndVisible]; return YES;
}
@end
int main(int argc,char** argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(DirectApp.class)); } }
