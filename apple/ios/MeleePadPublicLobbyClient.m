#import "MeleePadPublicLobbyClient.h"
#import "MeleePadDiagnostics.h"

#import <TargetConditionals.h>

NSString *const MeleePadPublicLobbyProtocol = @"moderngekko-netplay-8";
NSString *const MeleePadPublicLobbyProductID = @"meleepad";
static const NSUInteger MeleePadMaximumLobbyResponseBytes = 64 * 1024;

static NSString *MeleePadLobbyRoute(NSString *path) {
    NSString *cleanPath = [path componentsSeparatedByString:@"?"].firstObject;
    if ([cleanPath isEqualToString:@"/v1/sessions"]) return @"session_create";
    if ([cleanPath isEqualToString:@"/v1/rooms"]) return @"rooms_collection";
    if ([cleanPath isEqualToString:@"/v1/activity"]) return @"activity_collection";
    if ([cleanPath isEqualToString:@"/v1/blocks"]) return @"block_create";
    if ([cleanPath isEqualToString:@"/v1/reports"]) return @"report_create";
    if ([cleanPath hasSuffix:@"/join"]) return @"room_join";
    if ([cleanPath hasSuffix:@"/members/me/heartbeat"]) return @"member_heartbeat";
    if ([cleanPath hasSuffix:@"/heartbeat"]) return @"host_heartbeat";
    if ([cleanPath hasSuffix:@"/members/me"]) return @"member_leave";
    if ([cleanPath hasSuffix:@"/messages"]) return @"room_messages";
    if ([cleanPath hasPrefix:@"/v1/rooms/"]) return @"room_close";
    return @"unknown";
}

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
        @"product_id": MeleePadPublicLobbyProductID,
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

- (void)fetchActivityWithCompletion:(MeleePadLobbyResult)completion {
    [self requestMethod:@"GET" path:@"/v1/activity" body:nil authenticated:YES
             completion:completion];
}

- (void)publishRoomWithTraversalCode:(NSString *)traversalCode
                              region:(NSString *)region
                            capacity:(NSUInteger)capacity
                          completion:(MeleePadLobbyResult)completion {
    NSDictionary *body = @{
        @"traversal_code": traversalCode.lowercaseString,
        @"region": region.length > 0 ? region : @"auto",
        @"capacity": @(MAX(2, MIN(4, capacity))),
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

- (void)sendMessage:(NSString *)text completion:(MeleePadLobbyResult)completion {
    if (_activeRoomID.length == 0) {
        [self complete:completion result:nil error:@"Join a public room first."];
        return;
    }
    NSString *path = [NSString stringWithFormat:@"/v1/rooms/%@/messages", _activeRoomID];
    [self requestMethod:@"POST" path:path body:@{@"text": text}
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
    NSString *route = MeleePadLobbyRoute(path);
    if (!self.available) {
        MeleePadLog(@"online lobby route=%@ method=%@ result=unavailable", route, method);
        [self complete:completion result:nil error:@"Public lobby unavailable."];
        return;
    }
    if (authenticated && _token.length == 0) {
        MeleePadLog(@"online lobby route=%@ method=%@ result=missing-session", route, method);
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
            MeleePadLog(@"online lobby route=%@ method=%@ result=invalid-request bytes=%lu",
                route, method, (unsigned long)data.length);
            [self complete:completion result:nil error:@"The lobby request was invalid."];
            return;
        }
        request.HTTPBody = data;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    NSTimeInterval started = NSDate.timeIntervalSinceReferenceDate;
    NSUInteger requestBytes = request.HTTPBody.length;
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        NSDictionary *JSON = data.length > 0 && data.length <= MeleePadMaximumLobbyResponseBytes
            ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSString *message = nil;
        if (networkError != nil) {
            message = @"The public lobby could not be reached. Private rooms still work.";
        } else if (data.length > MeleePadMaximumLobbyResponseBytes) {
            message = @"The public lobby returned too much data.";
        } else if (HTTPResponse.statusCode == 401) {
            self->_token = nil;
            self->_activeRoomID = nil;
            self->_localSessionID = nil;
            self->_hosting = NO;
            message = @"The lobby session expired. Refresh to reconnect.";
        } else if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode >= 300) {
            NSDictionary *errorObject = [JSON[@"error"] isKindOfClass:NSDictionary.class]
                ? JSON[@"error"] : nil;
            message = [errorObject[@"message"] isKindOfClass:NSString.class]
                ? errorObject[@"message"] : @"The public lobby request failed.";
        } else if (![JSON isKindOfClass:NSDictionary.class]) {
            message = @"The public lobby returned an invalid response.";
        }
        NSString *result = networkError != nil ? @"network-error"
            : (data.length > MeleePadMaximumLobbyResponseBytes ? @"response-too-large"
            : (HTTPResponse.statusCode == 401 ? @"session-expired"
            : (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode >= 300 ? @"http-error"
            : (![JSON isKindOfClass:NSDictionary.class] ? @"invalid-response" : @"success"))));
        BOOL routinePoll = [route isEqualToString:@"host_heartbeat"] ||
            [route isEqualToString:@"member_heartbeat"] ||
            ([route isEqualToString:@"rooms_collection"] && [method isEqualToString:@"GET"]) ||
            ([route isEqualToString:@"activity_collection"] && [method isEqualToString:@"GET"]) ||
            ([route isEqualToString:@"room_messages"] && [method isEqualToString:@"GET"]);
        if (message.length > 0 || !routinePoll) {
            NSUInteger elapsedMilliseconds = (NSUInteger)MAX(0.0,
                (NSDate.timeIntervalSinceReferenceDate - started) * 1000.0);
            MeleePadLog(@"online lobby route=%@ method=%@ result=%@ status=%ld duration_ms=%lu request_bytes=%lu response_bytes=%lu",
                route, method, result, (long)HTTPResponse.statusCode,
                (unsigned long)elapsedMilliseconds, (unsigned long)requestBytes,
                (unsigned long)data.length);
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
