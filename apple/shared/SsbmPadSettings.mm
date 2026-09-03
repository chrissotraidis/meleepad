#import "SsbmPadSettings.h"

@implementation SsbmPadSettings {
    NSMutableDictionary<NSString *, NSNumber *> *_controlSizeScales;
}

+ (instancetype)sharedSettings {
    static SsbmPadSettings *shared = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [[SsbmPadSettings alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if ((self = [super init])) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // The former user-facing 90% CPU-clock mode was removed because it
        // changes game timing without making the failing workload playable.
        // Clear its old preference so existing installs always return to the
        // stable product profile.
        [defaults removeObjectForKey:@"SsbmPadExperimentalPerformanceMode"];
        NSDictionary *saved = [defaults dictionaryForKey:@"SsbmPadControlSizeScales"];
        _controlSizeScales = saved ? [saved mutableCopy] : [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSInteger)renderScale {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"SsbmPadRenderScale"];
    if (value == nil)
        return 1;
    NSInteger scale = value.integerValue;
    return scale < 1 ? 1 : (scale > 4 ? 4 : scale);
}

- (void)setRenderScale:(NSInteger)renderScale {
    NSInteger clamped = renderScale < 1 ? 1 : (renderScale > 4 ? 4 : renderScale);
    [[NSUserDefaults standardUserDefaults] setInteger:clamped forKey:@"SsbmPadRenderScale"];
}

- (float)renderScaleFloat {
    switch (self.renderScale) {
    case 1: return 1.0f;
    case 2: return 2.0f;
    case 3: return 3.0f;
    case 4: return 4.0f;
    default: return 1.0f;
    }
}

- (SsbmPadAspectRatioMode)aspectRatioMode {
    NSInteger mode = [[NSUserDefaults standardUserDefaults]
        integerForKey:@"SsbmPadAspectRatioMode"];
    if (mode < SsbmPadAspectRatioOriginal || mode > SsbmPadAspectRatioFillScreen)
        return SsbmPadAspectRatioOriginal;
    return (SsbmPadAspectRatioMode)mode;
}

- (void)setAspectRatioMode:(SsbmPadAspectRatioMode)aspectRatioMode {
    NSInteger mode = aspectRatioMode;
    if (mode < SsbmPadAspectRatioOriginal || mode > SsbmPadAspectRatioFillScreen)
        mode = SsbmPadAspectRatioOriginal;
    [[NSUserDefaults standardUserDefaults] setInteger:mode
                                               forKey:@"SsbmPadAspectRatioMode"];
}

- (BOOL)showFPSCounter {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"SsbmPadShowFPSCounter"];
}

- (void)setShowFPSCounter:(BOOL)showFPSCounter {
    [[NSUserDefaults standardUserDefaults] setBool:showFPSCounter
                                            forKey:@"SsbmPadShowFPSCounter"];
}

- (BOOL)hideTouchControlsWhenControllerConnected {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"SsbmPadHideControlsOnController"];
    return value == nil ? YES : value.boolValue;
}

- (void)setHideTouchControlsWhenControllerConnected:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"SsbmPadHideControlsOnController"];
}

- (BOOL)modernCStickHorizontal {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"SsbmPadModernCStickHorizontal"];
}

- (void)setModernCStickHorizontal:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"SsbmPadModernCStickHorizontal"];
}

- (BOOL)rightStickSmashAttacks {
    NSNumber *value = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"SsbmPadRightStickSmashAttacks"];
    return value == nil ? YES : value.boolValue;
}

- (void)setRightStickSmashAttacks:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value
                                            forKey:@"SsbmPadRightStickSmashAttacks"];
}

- (CGFloat)controlOpacity {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"SsbmPadControlOpacity"];
    if (value == nil)
        return 0.82;
    return MAX(0.25, MIN(1.0, value.doubleValue));
}

- (void)setControlOpacity:(CGFloat)controlOpacity {
    [[NSUserDefaults standardUserDefaults] setDouble:MAX(0.25, MIN(1.0, controlOpacity))
                                              forKey:@"SsbmPadControlOpacity"];
}

- (CGFloat)controlSizeScale {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"SsbmPadControlSizeScale"];
    if (value == nil)
        return 1.0;
    return MAX(0.70, MIN(1.35, value.doubleValue));
}

- (void)setControlSizeScale:(CGFloat)controlSizeScale {
    [[NSUserDefaults standardUserDefaults] setDouble:MAX(0.70, MIN(1.35, controlSizeScale))
                                              forKey:@"SsbmPadControlSizeScale"];
}

- (BOOL)editingControlLayout {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"SsbmPadEditingControlLayout"];
}

- (void)setEditingControlLayout:(BOOL)editingControlLayout {
    [[NSUserDefaults standardUserDefaults] setBool:editingControlLayout forKey:@"SsbmPadEditingControlLayout"];
}

- (CGFloat)sizeScaleForControl:(NSString *)identifier {
    NSNumber *saved = _controlSizeScales[identifier];
    if (saved == nil)
        return 1.0;
    return MAX(0.60, MIN(1.75, saved.doubleValue));
}

- (void)setSizeScale:(CGFloat)scale forControl:(NSString *)identifier {
    _controlSizeScales[identifier] = @(MAX(0.60, MIN(1.75, scale)));
    [[NSUserDefaults standardUserDefaults] setObject:_controlSizeScales
                                              forKey:@"SsbmPadControlSizeScales"];
}

- (void)resetControlSizeScales {
    [_controlSizeScales removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SsbmPadControlSizeScales"];
}

- (NSString *)retainedGameDataPath {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"SsbmPadRetainedGameDataPath"];
}

- (void)setRetainedGameDataPath:(NSString *)retainedGameDataPath {
    if (retainedGameDataPath == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SsbmPadRetainedGameDataPath"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:retainedGameDataPath
                                                  forKey:@"SsbmPadRetainedGameDataPath"];
    }
}

- (NSString *)extractedGameRoot {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"SsbmPadExtractedGameRoot"];
}

- (void)setExtractedGameRoot:(NSString *)extractedGameRoot {
    if (extractedGameRoot == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SsbmPadExtractedGameRoot"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:extractedGameRoot
                                                  forKey:@"SsbmPadExtractedGameRoot"];
    }
}

- (void)synchronize {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
