#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MeleePadOnlinePlayViewController;
@class MeleePadPublicLobbyClient;

typedef NS_ENUM(NSInteger, MeleePadOnlinePlayRole) {
    MeleePadOnlinePlayRoleHost,
    MeleePadOnlinePlayRoleJoin,
};

@protocol MeleePadOnlinePlayViewControllerDelegate <NSObject>
- (void)onlinePlayViewController:(MeleePadOnlinePlayViewController *)controller
                     requestsHostWithNickname:(NSString *)nickname
                                         port:(uint16_t)port
                                 internetRoom:(BOOL)internetRoom
                              automaticBuffer:(BOOL)automaticBuffer
                                 bufferFrames:(NSUInteger)bufferFrames;
- (void)onlinePlayViewController:(MeleePadOnlinePlayViewController *)controller
                     requestsJoinWithNickname:(NSString *)nickname
                                      address:(NSString *)address
                                         port:(uint16_t)port
                                 internetRoom:(BOOL)internetRoom
                              automaticBuffer:(BOOL)automaticBuffer
                                 bufferFrames:(NSUInteger)bufferFrames;
- (void)onlinePlayViewController:(MeleePadOnlinePlayViewController *)controller
                requestsReady:(BOOL)ready;
- (void)onlinePlayViewController:(MeleePadOnlinePlayViewController *)controller
    requestsSendPeerChatMessage:(NSString *)message
                     completion:(void (^)(NSString *_Nullable error))completion;
- (void)onlinePlayViewControllerRequestsStart:(MeleePadOnlinePlayViewController *)controller;
- (void)onlinePlayViewControllerRequestsReturnToGame:(MeleePadOnlinePlayViewController *)controller;
- (void)onlinePlayViewControllerRequestsCancel:(MeleePadOnlinePlayViewController *)controller;
@end

/* Native touch-first setup and lobby surface. Networking remains owned by the
 * reusable ModernGekko NetplaySession and is reflected through these methods. */
@interface MeleePadOnlinePlayViewController : UIViewController

@property(nonatomic, weak, nullable) id<MeleePadOnlinePlayViewControllerDelegate> delegate;

- (instancetype)initWithPublicLobbyClient:(MeleePadPublicLobbyClient *)client;

- (void)showConnectingWithMessage:(NSString *)message;
- (void)showLobbyForRole:(MeleePadOnlinePlayRole)role
                   players:(NSArray<NSDictionary<NSString *, id> *> *)players
              bufferFrames:(NSUInteger)bufferFrames
           automaticBuffer:(BOOL)automaticBuffer
                  canStart:(BOOL)canStart
            sessionRunning:(BOOL)sessionRunning
                  roomCode:(nullable NSString *)roomCode
                  messages:(NSArray<NSDictionary<NSString *, id> *> *)messages
                    status:(nullable NSString *)status;
- (void)showError:(NSString *)message;
- (void)resetToSetup;

@end

NS_ASSUME_NONNULL_END
