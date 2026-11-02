#import "MeleePadNSOGCBridge.h"

#import "NSOGC/NSOGCKit.h"
#import "MeleePadDiagnostics.h"
#import "MeleePadInputMixer.h"

#include <cmath>

static NSString *const kEnabledKey = @"MeleePadNSOGCEnabled";

// The controller is a GameCube pad, so its buttons map one to one; the
// player's face-button mapping is for other layouts. L and R are the
// triggers' own end-of-travel clicks, as on the original controller.
static MeleePadInputState MeleePadInputStateFromNSOGC(const nsogc_state &pad) {
    static const struct {
        uint32_t pad;
        uint16_t meleepad;
    } kButtons[] = {
        {NSOGC_BUTTON_A, MeleePadButtonA},
        {NSOGC_BUTTON_B, MeleePadButtonB},
        {NSOGC_BUTTON_X, MeleePadButtonX},
        {NSOGC_BUTTON_Y, MeleePadButtonY},
        {NSOGC_BUTTON_Z, MeleePadButtonZ},
        {NSOGC_BUTTON_START, MeleePadButtonStart},
        {NSOGC_BUTTON_L, MeleePadButtonL},
        {NSOGC_BUTTON_R, MeleePadButtonR},
        {NSOGC_BUTTON_DPAD_UP, MeleePadButtonDpadUp},
        {NSOGC_BUTTON_DPAD_DOWN, MeleePadButtonDpadDown},
        {NSOGC_BUTTON_DPAD_LEFT, MeleePadButtonDpadLeft},
        {NSOGC_BUTTON_DPAD_RIGHT, MeleePadButtonDpadRight},
    };
    MeleePadInputState state = {};
    state.connected = 1;
    for (const auto &button : kButtons) {
        if (pad.buttons & button.pad)
            state.buttons |= button.meleepad;
    }
    state.stickX = (int8_t)std::lround(pad.stick_x * 127.0f);
    state.stickY = (int8_t)std::lround(pad.stick_y * 127.0f);
    state.cStickX = (int8_t)std::lround(pad.cstick_x * 127.0f);
    state.cStickY = (int8_t)std::lround(pad.cstick_y * 127.0f);
    state.triggerL = (uint8_t)std::lround(pad.trigger_l * 255.0f);
    state.triggerR = (uint8_t)std::lround(pad.trigger_r * 255.0f);
    return state;
}

@interface MeleePadNSOGCBridge () <NSOGCManagerDelegate>
@end

@implementation MeleePadNSOGCBridge {
    NSMutableDictionary<NSNumber *, NSOGCController *> *_controllers;  // by player index
    BOOL _configured;
    BOOL _bluetoothAvailable;
}

+ (instancetype)sharedBridge {
    static MeleePadNSOGCBridge *bridge;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        bridge = [[MeleePadNSOGCBridge alloc] init];
    });
    return bridge;
}

- (instancetype)init {
    if ((self = [super init])) {
        // Off until the player chooses Connect in the Controls menu, so nobody
        // without one of these controllers gets the Bluetooth prompt or a scan.
        [NSUserDefaults.standardUserDefaults registerDefaults:@{kEnabledKey : @NO}];
        _controllers = [NSMutableDictionary dictionary];
        _bluetoothAvailable = YES;
    }
    return self;
}

- (BOOL)enabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kEnabledKey];
}

- (void)setEnabled:(BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kEnabledKey];
}

- (void)start {
    if (self.enabled)
        [self startManager];
}

- (void)startManager {
    NSOGCManager *manager = NSOGCManager.sharedManager;
    if (!_configured) {
        _configured = YES;
        manager.maximumControllers = 4;  // the GameCube's four ports
        // Input goes straight from the Bluetooth queue into the locked mixer
        // and players 2-4's pipes.
        manager.deliversInputOnBluetoothQueue = YES;
        manager.delegate = self;
        manager.logHandler = ^(NSString *line) {
            MeleePadLog(@"nsogc %@", line);
        };
    }
    [manager start];
}

- (void)connect {
    self.enabled = YES;
    [self startManager];
    MeleePadLog(@"nsogc turned on");
    [self notifyConnectionChanged];
}

- (void)disconnect {
    self.enabled = NO;
    [NSOGCManager.sharedManager stop];
    MeleePadLog(@"nsogc turned off");
    [self notifyConnectionChanged];
}

- (void)forgetControllers {
    NSOGCManager *manager = NSOGCManager.sharedManager;
    [manager forgetControllers];
    // Forgotten first, so the disconnections do not wait for them to come back.
    for (NSOGCController *controller in _controllers.allValues)
        [manager disconnectController:controller];
    MeleePadLog(@"nsogc controllers forgotten");
    [self notifyConnectionChanged];
}

- (MeleePadNSOGCStatus)status {
    if (!self.enabled)
        return MeleePadNSOGCStatusOff;
    if (_controllers.count > 0)
        return MeleePadNSOGCStatusConnected;
    if (!_bluetoothAvailable)
        return MeleePadNSOGCStatusUnavailable;
    return MeleePadNSOGCStatusSearching;
}

- (BOOL)playerOneConnected {
    return _controllers[@0] != nil;
}

- (NSUInteger)connectedCount {
    return _controllers.count;
}

- (BOOL)hasRememberedControllers {
    return NSOGCManager.sharedManager.hasRememberedControllers;
}

- (NSArray<NSString *> *)connectedDescriptions {
    NSMutableArray<NSString *> *descriptions = [NSMutableArray array];
    for (NSInteger player = 0; player < 4; player++) {
        NSOGCController *controller = _controllers[@(player)];
        if (controller != nil)
            [descriptions addObject:[NSString stringWithFormat:@"Player %ld: %@", (long)player + 1,
                                                               controller.name]];
    }
    return descriptions;
}

- (void)notifyConnectionChanged {
    if (self.connectionChangedHandler != nil)
        self.connectionChangedHandler();
}

#pragma mark - NSOGCManagerDelegate (main thread)

- (void)manager:(NSOGCManager *)manager didConnectController:(NSOGCController *)controller {
    NSInteger player = controller.playerIndex;
    if (player < 0 || player > 3 || _controllers[@(player)] != nil)
        return;
    _controllers[@(player)] = controller;
    if (player == 0) {
        void (^inputUpdated)(void) = self.playerOneInputHandler;
        // Runs on the Bluetooth queue for every report.
        controller.inputHandler = ^(NSOGCController *source, nsogc_state state) {
            (void)source;
            [[MeleePadInputMixer sharedMixer] setInputState:MeleePadInputStateFromNSOGC(state)
                                                  fromTouch:NO];
            if (inputUpdated != nil)
                inputUpdated();
        };
    } else {
        void (^portInput)(NSInteger, MeleePadInputState) = self.portInputHandler;
        controller.inputHandler = ^(NSOGCController *source, nsogc_state state) {
            (void)source;
            if (portInput != nil)
                portInput(player, MeleePadInputStateFromNSOGC(state));
        };
        if (self.portConnectionHandler != nil)
            self.portConnectionHandler(player, YES);
    }
    MeleePadLog(@"nsogc controller connected player=%ld name=%@", (long)player + 1, controller.name);
    [self notifyConnectionChanged];
}

- (void)manager:(NSOGCManager *)manager didDisconnectController:(NSOGCController *)controller {
    NSInteger player = controller.playerIndex;
    if (_controllers[@(player)] != controller)
        return;
    controller.inputHandler = nil;
    [_controllers removeObjectForKey:@(player)];
    // NSOGCKit already delivered a neutral state on the Bluetooth queue, which
    // stays the only writer of players 2-4's pipes.
    if (player == 0) {
        [[MeleePadInputMixer sharedMixer] clearInputFromTouch:NO];
    } else if (self.portConnectionHandler != nil) {
        self.portConnectionHandler(player, NO);
    }
    MeleePadLog(@"nsogc controller disconnected player=%ld", (long)player + 1);
    [self notifyConnectionChanged];
}

- (void)manager:(NSOGCManager *)manager bluetoothAvailabilityDidChange:(BOOL)available {
    _bluetoothAvailable = available;
    [self notifyConnectionChanged];
}

@end
