#import "MeleePadSlippiHost.h"
#import "MeleePadDiagnostics.h"

#import <Security/Security.h>
#import <TargetConditionals.h>
#import <CommonCrypto/CommonDigest.h>
#import <pthread.h>

#include "slippi-direct-probe.hpp"
#include "slippi-probe-account.hpp"
#include "Core/Config/GraphicsSettings.h"
#include "VideoCommon/VideoConfig.h"

#include <algorithm>
#include <atomic>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <string>
#include <thread>

static NSString *const MeleePadSlippiAccountService =
    @"com.meleepad.MeleePad.slippi-account";

static NSMutableDictionary *MeleePadSlippiAccountQuery(void) {
    return [@{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService : MeleePadSlippiAccountService,
              (__bridge id)kSecAttrAccount : @"explicit-import",
              (__bridge id)kSecAttrSynchronizable : @NO} mutableCopy];
}

#if TARGET_OS_SIMULATOR
// Unsigned simulator builds do not have the production Keychain entitlement.
// Keep simulator-only QA imports inside the app sandbox; device builds always
// use the device-only Keychain item below.
static NSString *MeleePadSlippiSimulatorAccountPath(void) {
    NSString *support = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    return [support stringByAppendingPathComponent:@"Slippi/user.json"];
}
#endif

static NSData *MeleePadSlippiReadAccount(void) {
    NSMutableDictionary *query = MeleePadSlippiAccountQuery();
    query[(__bridge id)kSecReturnData] = @YES;
    CFTypeRef result = nullptr;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) == errSecSuccess)
        return CFBridgingRelease(result);
#if TARGET_OS_SIMULATOR
    return [NSData dataWithContentsOfFile:MeleePadSlippiSimulatorAccountPath()];
#else
    return nil;
#endif
}

static NSString *MeleePadSlippiExitMessage(NSInteger code) {
    switch (code) {
    case 2: return @"Slippi could not start because its private run directory already exists.";
    case 3: return @"Slippi could not create the native runtime.";
    case 4: return @"Slippi requires USA Melee v1.02 game data.";
    case 5: return @"Slippi could not load the v1.02 GameINI.";
    case 6: return @"The native Slippi code set is incomplete.";
    case 7: return @"Slippi stopped after a runtime error.";
    case 8: return @"Slippi reported a native runtime or graphics error.";
    case 20: return @"The imported Slippi account could not be staged privately.";
    case 21: return @"Slippi stopped before its private diagnostics could be written.";
    default: return [NSString stringWithFormat:@"Slippi stopped (code %ld).", (long)code];
    }
}

@implementation MeleePadSlippiHost {
    CAMetalLayer *_layer;
    std::thread *_thread;
    std::atomic<bool> *_starting;
    std::atomic<bool> *_running;
    std::mutex *_accountMutex;
}

static void MeleePadSlippiWriteWorkerFinished(const std::filesystem::path &runRoot,
                                              NSInteger exitCode) {
    std::error_code error;
    std::filesystem::create_directories(runRoot, error);
    if (error)
        return;
    const auto temporary = runRoot / "worker-finished.json.tmp";
    const auto target = runRoot / "worker-finished.json";
    std::ofstream output(temporary, std::ios::trunc);
    if (!output)
        return;
    output << "{\"complete\":true,\"worker_finished\":true,\"exit_code\":"
           << exitCode << "}\n";
    output.flush();
    if (!output) {
        output.close();
        std::filesystem::remove(temporary, error);
        return;
    }
    output.close();
    std::filesystem::rename(temporary, target, error);
    if (error)
        std::filesystem::remove(temporary, error);
}

- (instancetype)initWithLayer:(CAMetalLayer *)layer {
    if ((self = [super init])) {
        _layer = layer;
        _thread = new std::thread();
        _starting = new std::atomic<bool>(false);
        _running = new std::atomic<bool>(false);
        _accountMutex = new std::mutex();
    }
    return self;
}

- (BOOL)isRunning {
    return _running->load(std::memory_order_acquire) ||
           _starting->load(std::memory_order_acquire);
}

- (BOOL)hasImportedAccount {
    return MeleePadSlippiReadAccount() != nil;
}

+ (NSUInteger)removeAbandonedAccountCopiesAtUserDirectory:(NSString *)userDirectory {
    return SlippiProbeAccount::RemoveAbandonedRuntimeCopies(
        std::filesystem::path(userDirectory.fileSystemRepresentation) / "SlippiDirectRuns");
}

- (NSString *)matchmakingStatusSummary {
    if (!self.isRunning)
        return @"Slippi is not running.";
    // Read the atomic observation published by the guest's EXI status read,
    // never the matchmaking worker's non-atomic state or cumulative counters.
    switch (SlippiDirectProbe::last_matchmaking_state.load(std::memory_order_acquire)) {
    case 1:
        return @"Connecting to matchmaking. Your search has not been accepted yet.";
    case 2:
        return @"The matchmaking server accepted your search. Waiting for an opponent assignment.\n\nThis does not tell us how many players are online or why a match has not been assigned. Press Z in the game to cancel.";
    case 3:
        return @"An opponent was assigned. Connecting to the other player.";
    case 4:
        return @"Connected to the other player. Check the game for character selection and match progress.";
    case 5:
        return @"Matchmaking reported an error. Return to the game to read it and press Z to clear it.";
    case 0:
        return @"No active search. Choose an online mode in the game. Direct and Teams require a code.";
    default:
        return @"Waiting for the game's matchmaking status. Return to the game to continue.";
    }
}

- (MeleePadSlippiConnectionMetrics)connectionMetrics {
    if (!self.isRunning)
        return {};
    return {
        slippi_network_diagnostics.connected_peer.load(std::memory_order_acquire) != nullptr,
        SlippiDirectProbe::game_starts.load(std::memory_order_relaxed) >
            SlippiDirectProbe::game_ends.load(std::memory_order_relaxed),
        slippi_network_diagnostics.ping_samples.load(std::memory_order_acquire),
        slippi_network_diagnostics.ping_total_us.load(std::memory_order_relaxed),
        slippi_network_diagnostics.input_stalls.load(std::memory_order_relaxed),
    };
}

- (BOOL)storeAccountData:(NSData *)data error:(NSString **)error {
    std::string normalized;
    if (data.length == 0 ||
        !SlippiProbeAccount::Normalize(
            std::string((const char *)data.bytes, data.length), normalized)) {
        if (error != nullptr)
            *error = @"Select your own Slippi user.json export.";
        return NO;
    }

    NSData *clean = [NSData dataWithBytes:normalized.data() length:normalized.size()];
#if TARGET_OS_SIMULATOR
    NSString *path = MeleePadSlippiSimulatorAccountPath();
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSError *directoryError = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:directory
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:&directoryError] ||
        ![clean writeToFile:path options:NSDataWritingAtomic error:&directoryError] ||
        ![[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions : @0600}
                                         ofItemAtPath:path error:&directoryError]) {
        MeleePadLog(@"Slippi simulator account write failed");
        if (error != nullptr)
            *error = @"MeleePad could not store the Slippi account in its simulator data.";
        return NO;
    }
    return YES;
#else
    NSMutableDictionary *values = [@{
        (__bridge id)kSecValueData : clean,
        (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    } mutableCopy];
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)MeleePadSlippiAccountQuery(),
                                    (__bridge CFDictionaryRef)values);
    if (status == errSecItemNotFound) {
        [values addEntriesFromDictionary:MeleePadSlippiAccountQuery()];
        status = SecItemAdd((__bridge CFDictionaryRef)values, nullptr);
    }
    if (status != errSecSuccess) {
        MeleePadLog(@"Slippi account Keychain write failed status=%d", (int)status);
        if (error != nullptr)
            *error = @"MeleePad could not store the Slippi account in this device's Keychain.";
        return NO;
    }
    return YES;
#endif
}

- (void)setRenderScale:(NSInteger)scale {
    // Starting the worker precedes creation of Dolphin configuration layers.
    auto layer = Config::GetLayer(Config::LayerType::CurrentRun);
    if (!self.isRunning || !layer) return;
    NSInteger clamped = MAX(1, MIN(4, scale));
    if (layer->Set(Config::GFX_EFB_SCALE, static_cast<int>(clamped)))
        Config::OnConfigChanged();
    MeleePadLog(@"Slippi render scale=%ld source=live", (long)clamped);
}

- (void)setAspectRatioMode:(MeleePadAspectRatioMode)mode {
    // Starting the worker precedes creation of Dolphin configuration layers.
    auto layer = Config::GetLayer(Config::LayerType::CurrentRun);
    if (!self.isRunning || !layer) return;
    // Stretch the output only. Keep the gameplay projection unchanged online.
    bool changed = layer->Set(Config::GFX_WIDESCREEN_HACK, false);
    if (mode == MeleePadAspectRatioOriginal) {
        changed |= layer->Set(Config::GFX_ASPECT_RATIO, AspectMode::ForceStandard);
    } else {
        CGSize size = mode == MeleePadAspectRatioWidescreen
            ? CGSizeMake(16, 9) : _layer.drawableSize;
        changed |= layer->Set(Config::GFX_CUSTOM_ASPECT_RATIO_WIDTH, MAX(1, (int)size.width));
        changed |= layer->Set(Config::GFX_CUSTOM_ASPECT_RATIO_HEIGHT, MAX(1, (int)size.height));
        changed |= layer->Set(Config::GFX_ASPECT_RATIO, AspectMode::CustomStretch);
    }
    if (changed) Config::OnConfigChanged();
    MeleePadLog(@"Slippi aspect mode=%ld source=live", (long)mode);
}

- (BOOL)removeImportedAccount {
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)MeleePadSlippiAccountQuery());
#if TARGET_OS_SIMULATOR
    NSError *error = nil;
    BOOL removed = [[NSFileManager defaultManager]
        removeItemAtPath:MeleePadSlippiSimulatorAccountPath() error:&error];
    return (status == errSecSuccess || status == errSecItemNotFound) &&
           (removed || error.code == NSFileNoSuchFileError || error == nil);
#else
    return status == errSecSuccess || status == errSecItemNotFound;
#endif
}

- (void)startWithGameRoot:(NSString *)gameRoot
            discImagePath:(NSString *)discImagePath
               modulePath:(NSString *)modulePath
            userDirectory:(NSString *)userDirectory
                  onStart:(dispatch_block_t)onStart
    onError:(void (^)(NSString *))onError
              onFinished:(void (^)(NSInteger))onFinished {
    if ([self isRunning])
        return;
    NSData *accountData = MeleePadSlippiReadAccount();
    if (accountData == nil) {
        MeleePadLog(@"native Slippi start blocked reason=account-missing");
        if (onError != nil)
            onError(@"Import your own Slippi user.json before starting Slippi.");
        return;
    }

    NSString *runRoot = [userDirectory stringByAppendingPathComponent:@"SlippiDirectRuns"];
    NSString *run = [runRoot stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSString *runtimeUser = [run stringByAppendingPathComponent:@"User"];
    NSError *directoryError = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:runRoot
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&directoryError]) {
        if (onError != nil)
            onError(@"MeleePad could not create its private Slippi run directory.");
        return;
    }
    [[NSURL fileURLWithPath:runRoot]
        setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];

    std::string game = gameRoot.UTF8String ?: "";
    std::string iso = discImagePath.UTF8String ?: "";
    std::string module = modulePath.UTF8String ?: "";
    std::string user = runtimeUser.UTF8String ?: "";
    std::string account((const char *)accountData.bytes, accountData.length);
    const int inputDelayFrames = static_cast<int>(
        [MeleePadSettings sharedSettings].slippiInputDelayFrames);
    if (_thread->joinable())
        _thread->join();
    SlippiDirectProbe::ResetTelemetry();
    *_starting = true;
    SlippiDirectProbe::stop.store(false, std::memory_order_release);
    SlippiDirectProbe::account_boot_check =
        [NSProcessInfo.processInfo.arguments containsObject:@"-meleepadSlippiAccountBootCheck"];
    SlippiDirectProbe::menu_probe =
        [NSProcessInfo.processInfo.arguments containsObject:@"-meleepadSlippiMenuProbe"];

    void (^startBlock)(void) = [onStart copy];
    void (^errorBlock)(NSString *) = [onError copy];
    void (^finishedBlock)(NSInteger) = [onFinished copy];
    _thread->operator=(std::thread([self, game = std::move(game), iso = std::move(iso),
                                      module = std::move(module), user = std::move(user),
                                      account = std::move(account), inputDelayFrames,
                                      startBlock, errorBlock, finishedBlock] {
        @autoreleasepool {
            // Hash the exact resolved file, rather than a different bundled copy.
            std::ifstream moduleFile(module, std::ios::binary);
            CC_SHA256_CTX hash;
            CC_SHA256_Init(&hash);
            char buffer[65536];
            while (moduleFile.read(buffer, sizeof(buffer)) || moduleFile.gcount())
                CC_SHA256_Update(&hash, buffer, (CC_LONG)moduleFile.gcount());
            unsigned char digest[CC_SHA256_DIGEST_LENGTH];
            CC_SHA256_Final(digest, &hash);
            NSMutableString *moduleHash = [NSMutableString string];
            for (unsigned char byte : digest)
                [moduleHash appendFormat:@"%02x", byte];
            qos_class_t qos = QOS_CLASS_UNSPECIFIED;
            pthread_get_qos_class_np(pthread_self(), &qos, nullptr);
            MeleePadLog(@"Slippi module path=%s sha256=%@ readable=%d thermal=%ld lowPower=%d refreshHz=%ld qos=%u",
                        module.c_str(), moduleHash, moduleFile.eof(),
                        (long)NSProcessInfo.processInfo.thermalState,
                        NSProcessInfo.processInfo.isLowPowerModeEnabled,
                        (long)UIScreen.mainScreen.maximumFramesPerSecond,
                        (unsigned)qos);
            *self->_starting = false;
            *self->_running = true;
            NSInteger exitCode = SlippiDirectMain(
                game.c_str(), iso.c_str(), module.c_str(), user.c_str(), account,
                (__bridge void *)self->_layer, inputDelayFrames, [startBlock] {
                    if (startBlock != nil)
                        dispatch_async(dispatch_get_main_queue(), startBlock);
                });
            MeleePadLog(@"Slippi runtime returned thermal=%ld", (long)NSProcessInfo.processInfo.thermalState);
            MeleePadSlippiWriteWorkerFinished(
                std::filesystem::path(user).parent_path(), exitCode);
            *self->_running = false;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (exitCode != 0 && errorBlock != nil)
                    errorBlock(MeleePadSlippiExitMessage(exitCode));
                if (finishedBlock != nil)
                    finishedBlock(exitCode);
            });
        }
    }));
}

- (void)stop {
    if ([self isRunning])
        SlippiDirectProbe::stop.store(true, std::memory_order_release);
    // A completed worker remains joinable until it is reaped. Always join it
    // here, even when isRunning is already false; deleting a joinable
    // std::thread would terminate the process during host teardown.
    if (_thread->joinable())
        _thread->join();
    *_starting = false;
    *_running = false;
}

- (void)publishInput:(MeleePadInputState)input {
    SlippiDirectProbe::Pad pad;
    pad.x = std::clamp((double)input.stickX / 127.0, -1.0, 1.0);
    pad.y = std::clamp((double)input.stickY / 127.0, -1.0, 1.0);
    pad.cx = std::clamp((double)input.cStickX / 127.0, -1.0, 1.0);
    pad.cy = std::clamp((double)input.cStickY / 127.0, -1.0, 1.0);
    pad.l = (double)input.triggerL / 255.0;
    pad.r = (double)input.triggerR / 255.0;
    pad.buttons = ((input.buttons & MeleePadButtonA) ? 1u : 0u) |
                  ((input.buttons & MeleePadButtonB) ? 2u : 0u) |
                  ((input.buttons & MeleePadButtonX) ? 4u : 0u) |
                  ((input.buttons & MeleePadButtonY) ? 8u : 0u) |
                  ((input.buttons & MeleePadButtonZ) ? 16u : 0u) |
                  ((input.buttons & MeleePadButtonStart) ? 32u : 0u);
    if (pad.x == 0.0 && (input.buttons & MeleePadButtonDpadLeft)) pad.x = -1.0;
    if (pad.x == 0.0 && (input.buttons & MeleePadButtonDpadRight)) pad.x = 1.0;
    if (pad.y == 0.0 && (input.buttons & MeleePadButtonDpadUp)) pad.y = -1.0;
    if (pad.y == 0.0 && (input.buttons & MeleePadButtonDpadDown)) pad.y = 1.0;
    {
        std::lock_guard lock(SlippiDirectProbe::pad_mutex);
        SlippiDirectProbe::pad = pad;
    }
}

- (void)dealloc {
    [self stop];
    delete _accountMutex;
    delete _starting;
    delete _running;
    delete _thread;
}

@end
