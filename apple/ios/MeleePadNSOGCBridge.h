#pragma once

#import <Foundation/Foundation.h>

#include "MeleePadInputState.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MeleePadNSOGCStatus) {
    MeleePadNSOGCStatusOff,          // turned off from the Controls menu
    MeleePadNSOGCStatusUnavailable,  // Bluetooth is off or not allowed for MeleePad
    MeleePadNSOGCStatusSearching,    // none connected yet: waiting for one in SYNC mode
    MeleePadNSOGCStatusConnected,    // one or more connected (and looking for more)
};

/* Connects up to four Nintendo Switch Online GameCube controllers made for the
 * Switch 2, which iOS has no driver for, over Bluetooth LE through NSOGCKit
 * (NSOGC/). The first is player one, like a GameController pad; the others
 * are players 2 to 4, each plugged into its own GameCube port while it is
 * connected. Main thread only, except where noted. */
@interface MeleePadNSOGCBridge : NSObject

+ (instancetype)sharedBridge;

/* Starts Bluetooth if the controllers were turned on from the Controls menu
 * (off until then). The first start shows the Bluetooth permission prompt. */
- (void)start;

/* Turns the controllers on: reconnects remembered ones and looks for one in
 * SYNC mode. The choice is kept across launches. */
- (void)connect;

/* Disconnects every controller and stays off until connect. */
- (void)disconnect;

/* Forgets remembered controllers and disconnects them; controllers in SYNC
 * mode can then pair. */
- (void)forgetControllers;

@property(nonatomic, readonly) MeleePadNSOGCStatus status;
@property(nonatomic, readonly) BOOL playerOneConnected;
@property(nonatomic, readonly) NSUInteger connectedCount;
@property(nonatomic, readonly) BOOL hasRememberedControllers;

/* "Player 1: name", one per connected controller, in player order. */
@property(nonatomic, readonly) NSArray<NSString *> *connectedDescriptions;

/* Called when a controller connects or disconnects, or the controllers are
 * turned on or off. */
@property(nonatomic, copy, nullable) void (^connectionChangedHandler)(void);

/* Bluetooth queue: player one's report just reached the input mixer, so the
 * game can be fed without waiting for the next tick. Set it before start. */
@property(nonatomic, copy, nullable) void (^playerOneInputHandler)(void);

/* Bluetooth queue: input for players 2-4 (GameCube ports 1-3). Set it before
 * start. */
@property(nonatomic, copy, nullable) void (^portInputHandler)(NSInteger port, MeleePadInputState state);

/* Players 2-4's controllers connecting and disconnecting (ports 1-3). */
@property(nonatomic, copy, nullable) void (^portConnectionHandler)(NSInteger port, BOOL connected);

@end

NS_ASSUME_NONNULL_END
