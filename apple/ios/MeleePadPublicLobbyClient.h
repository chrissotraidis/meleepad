#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MeleePadLobbyResult)(NSDictionary<NSString *, id> *_Nullable result,
                                    NSString *_Nullable error);

@interface MeleePadPublicLobbyClient : NSObject

@property(nonatomic, readonly, getter=isAvailable) BOOL available;
@property(nonatomic, readonly, nullable) NSString *activeRoomID;
@property(nonatomic, readonly, nullable) NSString *localSessionID;

- (instancetype)init;
- (void)prepareWithNickname:(NSString *)nickname completion:(MeleePadLobbyResult)completion;
- (void)fetchRoomsWithCompletion:(MeleePadLobbyResult)completion;
- (void)publishRoomWithTraversalCode:(NSString *)traversalCode
                              region:(NSString *)region
                          completion:(MeleePadLobbyResult)completion;
- (void)heartbeatInGame:(BOOL)inGame completion:(nullable MeleePadLobbyResult)completion;
- (void)joinRoomID:(NSString *)roomID completion:(MeleePadLobbyResult)completion;
- (void)leaveActiveRoomWithCompletion:(nullable MeleePadLobbyResult)completion;
- (void)closeHostedRoomWithCompletion:(nullable MeleePadLobbyResult)completion;
- (void)fetchMessagesAfter:(NSUInteger)messageID completion:(MeleePadLobbyResult)completion;
- (void)sendQuickMessage:(NSString *)kind completion:(MeleePadLobbyResult)completion;
- (void)hideSessionID:(NSString *)sessionID completion:(MeleePadLobbyResult)completion;
- (void)reportSessionID:(NSString *)sessionID
                 roomID:(NSString *)roomID
                 reason:(NSString *)reason
             completion:(MeleePadLobbyResult)completion;

@end

FOUNDATION_EXPORT NSString *const MeleePadPublicLobbyProtocol;

NS_ASSUME_NONNULL_END
