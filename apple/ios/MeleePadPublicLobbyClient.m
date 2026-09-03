#import "MeleePadPublicLobbyClient.h"

#import <TargetConditionals.h>

NSString *const MeleePadPublicLobbyProtocol = @"moderngekko-netplay-8";

@implementation MeleePadPublicLobbyClient {
    NSURL *_baseURL;
    NSURLSession *_session;
    NSString *_token;
    NSString *_nickname;
    NSString *_activeRoomID;
    NSString *_localSessionID;
    BOOL _hosting;
}

- (instancetype)init {
    self = [super init];
    if (self == nil)
        return nil;

    NSString *configured = NSProcessInfo.processInfo.environment[@"MELEEPAD_LOBBY_BASE_URL"];
    if (configured.length == 0)
        configured = [NSBundle.mainBundle objectForInfoDictionaryKey:@"MeleePadLobbyBaseURL"];
    NSURL *candidate = configured.length > 0 ? [NSURL URLWithString:configured] : nil;
    BOOL secure = [candidate.scheme.lowercaseString isEqualToString:@"https"];
#if TARGET_OS_SIMULATOR
    BOOL loopback = [candidate.scheme.lowercaseString isEqualToString:@"http"] &&
        ([candidate.host isEqualToString:@"127.0.0.1"] ||
         [candidate.host isEqualToString:@"localhost"]);
#else
    BOOL loopback = NO;
#endif
    if (candidate != nil && (secure || loopback)) {
        _baseURL = candidate;
        NSURLSessionConfiguration *configuration =
            NSURLSessionConfiguration.ephemeralSessionConfiguration;
        configuration.timeoutIntervalForRequest = 8.0;
        configuration.timeoutIntervalForResource = 12.0;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        configuration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        _session = [NSURLSession sessionWithConfiguration:configuration];
    }
    return self;
}

- (BOOL)isAvailable {
    return _baseURL != nil;
}

- (NSString *)activeRoomID {
    return _activeRoomID;
}

- (NSString *)localSessionID {
    return _localSessionID;
}

- (void)prepareWithNickname:(NSString *)nickname completion:(MeleePadLobbyResult)completion {
    if (!self.available) {
        [self complete:completion result:nil
                 error:@"Public games are not configured in this build. Private rooms still work."];
        return;
    }
    if (_token.length > 0 && [_nickname isEqualToString:nickname]) {
        [self complete:completion result:@{@"ready": @YES} error:nil];
        return;
    }
    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
        ?: @"unknown";
    NSString *build = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]
        ?: @"unknown";
    NSDictionary *body = @{
        @"display_name": nickname,
        @"app_version": version,
        @"build": build,
        @"protocol": MeleePadPublicLobbyProtocol,
        @"game_id": @"GALE01",
        @"game_revision": @"r0",
    };
    __weak MeleePadPublicLobbyClient *weakSelf = self;
    [self requestMethod:@"POST" path:@"/v1/sessions" body:body authenticated:NO
             completion:^(NSDictionary *result, NSString *error) {
        MeleePadPublicLobbyClient *strongSelf = weakSelf;
        if (strongSelf != nil && error.length == 0) {
            strongSelf->_token = result[@"token"];
            strongSelf->_localSessionID = result[@"session_id"];
            strongSelf->_nickname = [nickname copy];
        }
        [strongSelf complete:completion result:result error:error];
    }];
}

- (void)fetchRoomsWithCompletion:(MeleePadLobbyResult)completion {
    [self requestMethod:@"GET" path:@"/v1/rooms" body:nil authenticated:YES
             completion:completion];
}

- (void)publishRoomWithTraversalCode:(NSString *)traversalCode
                              region:(NSString *)region
                          completion:(MeleePadLobbyResult)completion {
    NSDictionary *body = @{
        @"traversal_code": traversalCode.lowercaseString,
        @"region": region.length > 0 ? region : @"auto",
    };
    __weak MeleePadPublicLobbyClient *weakSelf = self;
    [self requestMethod:@"POST" path:@"/v1/rooms" body:body authenticated:YES
             completion:^(NSDictionary *result, NSString *error) {
        MeleePadPublicLobbyClient *strongSelf = weakSelf;
        if (strongSelf != nil && error.length == 0) {
            strongSelf->_activeRoomID = result[@"room_id"];
            strongSelf->_hosting = YES;
        }
        [strongSelf complete:completion result:result error:error];
    }];
}

- (void)heartbeatInGame:(BOOL)inGame completion:(MeleePadLobbyResult)completion {
    if (_activeRoomID.length == 0) {
        [self complete:completion result:@{@"ok": @NO} error:nil];
        return;
    }
    NSString *path = _hosting
        ? [NSString stringWithFormat:@"/v1/rooms/%@/heartbeat", _activeRoomID]
        : [NSString stringWithFormat:@"/v1/rooms/%@/members/me/heartbeat", _activeRoomID];
    NSDictionary *body = _hosting
        ? @{@"state": inGame ? @"in_game" : @"waiting"} : @{};
    [self requestMethod:@"PUT" path:path body:body authenticated:YES completion:completion];
}

- (void)joinRoomID:(NSString *)roomID completion:(MeleePadLobbyResult)completion {
    NSString *path = [NSString stringWithFormat:@"/v1/rooms/%@/join", roomID];
    __weak MeleePadPublicLobbyClient *weakSelf = self;
    [self requestMethod:@"POST" path:path body:@{} authenticated:YES
             completion:^(NSDictionary *result, NSString *error) {
        MeleePadPublicLobbyClient *strongSelf = weakSelf;
        if (strongSelf != nil && error.length == 0) {
            strongSelf->_activeRoomID = result[@"room_id"];
            strongSelf->_hosting = NO;
        }
        [strongSelf complete:completion result:result error:error];
    }];
}

- (void)leaveActiveRoomWithCompletion:(MeleePadLobbyResult)completion {
    if (_activeRoomID.length == 0 || _hosting) {
        _activeRoomID = nil;
        [self complete:completion result:@{@"ok": @YES} error:nil];
        return;
    }
    NSString *roomID = [_activeRoomID copy];
    NSString *path = [NSString stringWithFormat:@"/v1/rooms/%@/members/me", roomID];
    __weak MeleePadPublicLobbyClient *weakSelf = self;
    [self requestMethod:@"DELETE" path:path body:nil authenticated:YES
             completion:^(NSDictionary *result, NSString *error) {
        MeleePadPublicLobbyClient *strongSelf = weakSelf;
        if (error.length == 0)
            strongSelf->_activeRoomID = nil;
        [strongSelf complete:completion result:result error:error];
    }];
}

- (void)closeHostedRoomWithCompletion:(MeleePadLobbyResult)completion {
    if (_activeRoomID.length == 0 || !_hosting) {
        [self complete:completion result:@{@"ok": @YES} error:nil];
        return;
    }
    NSString *path = [NSString stringWithFormat:@"/v1/rooms/%@", _activeRoomID];
    __weak MeleePadPublicLobbyClient *weakSelf = self;
    [self requestMethod:@"DELETE" path:path body:nil authenticated:YES
             completion:^(NSDictionary *result, NSString *error) {
        MeleePadPublicLobbyClient *strongSelf = weakSelf;
        if (error.length == 0) {
            strongSelf->_activeRoomID = nil;
            strongSelf->_hosting = NO;
        }
        [strongSelf complete:completion result:result error:error];
    }];
}

- (void)fetchMessagesAfter:(NSUInteger)messageID completion:(MeleePadLobbyResult)completion {
    if (_activeRoomID.length == 0) {
        [self complete:completion result:@{@"messages": @[]} error:nil];
        return;
    }
    NSString *path = [NSString stringWithFormat:@"/v1/rooms/%@/messages?after=%lu",
        _activeRoomID, (unsigned long)messageID];
    [self requestMethod:@"GET" path:path body:nil authenticated:YES completion:completion];
}

- (void)sendQuickMessage:(NSString *)kind completion:(MeleePadLobbyResult)completion {
    if (_activeRoomID.length == 0) {
        [self complete:completion result:nil error:@"Join a public room first."];
        return;
    }
    NSString *path = [NSString stringWithFormat:@"/v1/rooms/%@/messages", _activeRoomID];
    [self requestMethod:@"POST" path:path body:@{@"kind": kind}
          authenticated:YES completion:completion];
}

- (void)hideSessionID:(NSString *)sessionID completion:(MeleePadLobbyResult)completion {
    [self requestMethod:@"POST" path:@"/v1/blocks"
                   body:@{@"session_id": sessionID}
          authenticated:YES completion:completion];
}

- (void)reportSessionID:(NSString *)sessionID
                 roomID:(NSString *)roomID
                 reason:(NSString *)reason
             completion:(MeleePadLobbyResult)completion {
    [self requestMethod:@"POST" path:@"/v1/reports"
                   body:@{
                       @"session_id": sessionID,
                       @"room_id": roomID,
                       @"reason": reason,
                   }
          authenticated:YES completion:completion];
}

- (void)requestMethod:(NSString *)method
                  path:(NSString *)path
                  body:(NSDictionary *)body
         authenticated:(BOOL)authenticated
            completion:(MeleePadLobbyResult)completion {
    if (!self.available) {
        [self complete:completion result:nil error:@"Public lobby unavailable."];
        return;
    }
    if (authenticated && _token.length == 0) {
        [self complete:completion result:nil error:@"Refresh the public lobby to reconnect."];
        return;
    }
    NSURL *URL = [NSURL URLWithString:path relativeToURL:_baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = method;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (authenticated)
        [request setValue:[@"Bearer " stringByAppendingString:_token]
       forHTTPHeaderField:@"Authorization"];
    if (body != nil) {
        NSError *serializationError = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0
                                                        error:&serializationError];
        if (data == nil || data.length > 8 * 1024) {
            [self complete:completion result:nil error:@"The lobby request was invalid."];
            return;
        }
        request.HTTPBody = data;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        NSDictionary *JSON = data.length > 0
            ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSString *message = nil;
        if (networkError != nil) {
            message = @"The public lobby could not be reached. Private rooms still work.";
        } else if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode >= 300) {
            NSDictionary *errorObject = [JSON[@"error"] isKindOfClass:NSDictionary.class]
                ? JSON[@"error"] : nil;
            message = [errorObject[@"message"] isKindOfClass:NSString.class]
                ? errorObject[@"message"] : @"The public lobby request failed.";
        } else if (![JSON isKindOfClass:NSDictionary.class]) {
            message = @"The public lobby returned an invalid response.";
        }
        [self complete:completion result:JSON error:message];
    }];
    [task resume];
}

- (void)complete:(MeleePadLobbyResult)completion
           result:(NSDictionary *)result
            error:(NSString *)error {
    if (completion == nil)
        return;
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(result, error);
    });
}

@end
