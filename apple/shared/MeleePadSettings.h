#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MeleePadAspectRatioMode) {
    MeleePadAspectRatioOriginal = 0,
    MeleePadAspectRatioWidescreen = 1,
    MeleePadAspectRatioFillScreen = 2,
};

/* Persisted MeleePad settings shared by macOS, iOS, and iPadOS. Stored in
 * NSUserDefaults so each platform keeps the same user-facing options.
 */
@interface MeleePadSettings : NSObject

+ (instancetype)sharedSettings;

/* Render-resolution scale. 1 = native GameCube EFB, 2..4 = multiplier. */
@property(nonatomic, assign) NSInteger renderScale;
- (float)renderScaleFloat;

/* Output aspect ratio. Original 4:3 is the stable default; wider modes are
 * experimental and affect only game rendering, never touch-control layout. */
@property(nonatomic, assign) MeleePadAspectRatioMode aspectRatioMode;

/* Optional developer performance overlay. Off by default for normal play. */
@property(nonatomic, assign) BOOL showFPSCounter;

/* Touch-control presentation. */
@property(nonatomic, assign) BOOL hideTouchControlsWhenControllerConnected;
/* Reverses only the C-stick horizontal axis for modern camera movement. */
@property(nonatomic, assign) BOOL modernCStickHorizontal;
/* Converts the merged physical or touch C-stick to chargeable smash attacks
 * during combat. On by default; menus retain Melee's untouched C-stick. */
@property(nonatomic, assign) BOOL rightStickSmashAttacks;
/* Offline-only convenience. Enabling may become persistent if the game writes
 * its save while the unlock flags are active; disabling is not a rollback. */
@property(nonatomic, assign) BOOL unlockAllCharactersAndStages;
@property(nonatomic, assign) CGFloat controlOpacity;   // 0.25..1
@property(nonatomic, assign) CGFloat controlSizeScale; // 0.70..1.35
@property(nonatomic, assign) BOOL editingControlLayout;

/* Per-control size overrides (1.0 = default), keyed by control identifier. */
- (CGFloat)sizeScaleForControl:(NSString *)identifier;
- (void)setSizeScale:(CGFloat)scale forControl:(NSString *)identifier;
- (void)resetControlSizeScales;

/* Save/load the retained game-data path (Application Support on mobile). */
@property(nonatomic, copy, nullable) NSString *retainedGameDataPath;

/* Extracted game tree (sys/ + files/) produced from the retained image. */
@property(nonatomic, copy, nullable) NSString *extractedGameRoot;

- (void)synchronize;

@end

NS_ASSUME_NONNULL_END
