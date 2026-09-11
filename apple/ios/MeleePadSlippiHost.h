#pragma once

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#include "MeleePadInputState.h"

NS_ASSUME_NONNULL_BEGIN

/* Hosts the native Slippi runtime in the main MeleePad process. The runtime
 * owns the same CAMetalLayer as solo Melee, but is started only after the
 * ordinary runtime has stopped because Dolphin permits one active runtime per
 * process. Account data is normalized and stored only in this device's
 * Keychain; the runtime receives a short-lived private user.json copy. */
@interface MeleePadSlippiHost : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)hasImportedAccount;
- (BOOL)storeAccountData:(NSData *)data error:(NSString *_Nullable *_Nullable)error;
- (BOOL)removeImportedAccount;

- (void)startWithGameRoot:(NSString *)gameRoot
            discImagePath:(NSString *)discImagePath
               modulePath:(NSString *)modulePath
            userDirectory:(NSString *)userDirectory
                  onStart:(dispatch_block_t _Nullable)onStart
                 onError:(void (^ _Nullable)(NSString *message))onError
              onFinished:(void (^ _Nullable)(NSInteger exitCode))onFinished;
- (void)stop;
- (void)publishInput:(MeleePadInputState)input;

@property(nonatomic, readonly, getter=isRunning) BOOL running;

@end

NS_ASSUME_NONNULL_END
