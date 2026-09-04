#pragma once

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#include "MeleePadInputState.h"
#import "MeleePadSettings.h"

NS_ASSUME_NONNULL_BEGIN

/* Hosts the ModernGekko / Dolphin-derived compatibility runtime inside the
 * MeleePad iOS/iPadOS app. Owns the game thread, the CAMetalLayer render
 * surface handed to the Metal video backend, and the pipe-input bridge. */
@interface MeleePadCoreHost : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/* Boots the game on a background thread. Returns immediately; the game runs
 * until -stop is called. Reports errors through onError. */
- (void)startWithGameRoot:(NSString *)gameRoot
            discImagePath:(NSString *)discImagePath
              modulePath:(NSString *)modulePath
              userDirectory:(NSString *)userDirectory
                  onError:(void (^)(NSString *message))onError;

- (void)stop;

/* Stops solo play and creates the platform-neutral direct-IP session. All
 * callbacks arrive on the main queue. The match callback fires only after
 * synchronized boot data is installed and the netplay runtime has started. */
- (void)beginNetplayHostingWithNickname:(NSString *)nickname
                                   port:(uint16_t)port
                         usingTraversal:(BOOL)usingTraversal
                        automaticBuffer:(BOOL)automaticBuffer
                           bufferFrames:(NSUInteger)bufferFrames
                             completion:(void (^)(NSString *_Nullable error))completion;
- (void)beginNetplayJoiningAddress:(NSString *)address
                          nickname:(NSString *)nickname
                              port:(uint16_t)port
                    usingTraversal:(BOOL)usingTraversal
                   automaticBuffer:(BOOL)automaticBuffer
                      bufferFrames:(NSUInteger)bufferFrames
                        completion:(void (^)(NSString *_Nullable error))completion;
- (void)pollNetplayWithCompletion:(void (^)(NSDictionary<NSString *, id> *snapshot))completion;
- (void)setNetplayReady:(BOOL)ready;
- (void)sendNetplayChatMessage:(NSString *)message
                    completion:(void (^)(NSString *_Nullable error))completion;
- (void)requestNetplayStart;
- (void)endNetplayWithCompletion:(dispatch_block_t)completion;

@property(nonatomic, copy, nullable) dispatch_block_t onNetplayMatchStarted;
@property(nonatomic, copy, nullable) dispatch_block_t onNetplayMatchEnded;

/* Pauses/resumes emulation around iOS lifecycle and audio interruptions.
 * Resume also reactivates the app's AVAudioSession. */
- (void)pauseRuntimeForSystemEvent;
- (void)resumeRuntimeAfterSystemEvent;

/* Stops the current runtime (if any) and boots the game at gameRoot with the
 * given module. Used after an imported image is extracted. */
- (void)restartWithGameRoot:(NSString *)gameRoot
               discImagePath:(NSString *)discImagePath
                 modulePath:(NSString *)modulePath;

/* Publishes the normalized input snapshot to the game through the pipe
 * device. Safe to call from any thread at ~60 Hz. */
- (void)publishInput:(MeleePadInputState)input;

/* Applies the render-resolution scale (1 = native GameCube EFB, 2..4 = scale)
 * to the running runtime. Safe to call from any thread. */
- (void)setRenderScale:(NSInteger)scale;

/* Applies the output aspect ratio without resizing the Metal view or touch
 * overlay. Safe to call from any thread. */
- (void)setAspectRatioMode:(MeleePadAspectRatioMode)mode;

/* Current emulated FPS from the runtime (0 if not booted). */
- (double)currentFPS;

/* Emulation speed ratio relative to real time (1.0 = full speed). */
- (double)currentSpeed;

/* Video-interface updates per second, useful when FPS alone looks healthy. */
- (double)currentVPS;

/* True only while Melee's current scene is active combat. Used to keep
 * controller conveniences from changing menu, CSS, results, or cutscene input. */
- (BOOL)isGameplayScene;

/* The profile actually selected for this runtime, independent of a setting
 * changed after launch. */
- (NSString *)currentPerformanceProfile;

/* Internal (EFB) render resolution, e.g. "640x528". */
- (NSString *)efbResolution;

/* Bounded, privacy-safe runtime and graphics state for a user-generated
 * diagnostic report. */
- (NSString *)diagnosticSummary;

@property(nonatomic, readonly, getter=isRunning) BOOL running;

@end

NS_ASSUME_NONNULL_END
