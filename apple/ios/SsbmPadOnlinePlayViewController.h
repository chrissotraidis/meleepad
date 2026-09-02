#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SsbmPadOnlinePlayViewController;

typedef NS_ENUM(NSInteger, SsbmPadOnlinePlayRole) {
    SsbmPadOnlinePlayRoleHost,
    SsbmPadOnlinePlayRoleJoin,
};

@protocol SsbmPadOnlinePlayViewControllerDelegate <NSObject>
- (void)onlinePlayViewController:(SsbmPadOnlinePlayViewController *)controller
                     requestsHostWithNickname:(NSString *)nickname
                                         port:(uint16_t)port
                              automaticBuffer:(BOOL)automaticBuffer
                                 bufferFrames:(NSUInteger)bufferFrames;
- (void)onlinePlayViewController:(SsbmPadOnlinePlayViewController *)controller
                     requestsJoinWithNickname:(NSString *)nickname
                                      address:(NSString *)address
                                         port:(uint16_t)port
                              automaticBuffer:(BOOL)automaticBuffer
                                 bufferFrames:(NSUInteger)bufferFrames;
- (void)onlinePlayViewController:(SsbmPadOnlinePlayViewController *)controller
                requestsReady:(BOOL)ready;
- (void)onlinePlayViewControllerRequestsStart:(SsbmPadOnlinePlayViewController *)controller;
- (void)onlinePlayViewControllerRequestsCancel:(SsbmPadOnlinePlayViewController *)controller;
@end

/* Native touch-first setup and lobby surface. Networking remains owned by the
 * reusable ModernGekko NetplaySession and is reflected through these methods. */
@interface SsbmPadOnlinePlayViewController : UIViewController

@property(nonatomic, weak, nullable) id<SsbmPadOnlinePlayViewControllerDelegate> delegate;

- (void)showConnectingWithMessage:(NSString *)message;
- (void)showLobbyForRole:(SsbmPadOnlinePlayRole)role
                   players:(NSArray<NSDictionary<NSString *, id> *> *)players
              bufferFrames:(NSUInteger)bufferFrames
           automaticBuffer:(BOOL)automaticBuffer
                  canStart:(BOOL)canStart
                    status:(nullable NSString *)status;
- (void)showError:(NSString *)message;
- (void)resetToSetup;

@end

NS_ASSUME_NONNULL_END
