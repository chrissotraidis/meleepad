#import "MeleePadSettings.h"

@implementation MeleePadSettings {
    NSMutableDictionary<NSString *, NSNumber *> *_controlSizeScales;
}

+ (instancetype)sharedSettings {
    static MeleePadSettings *shared = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [[MeleePadSettings alloc] init];
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
        [defaults removeObjectForKey:@"MeleePadExperimentalPerformanceMode"];
        NSDictionary *saved = [defaults dictionaryForKey:@"MeleePadControlSizeScales"];
        _controlSizeScales = saved ? [saved mutableCopy] : [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSInteger)renderScale {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"MeleePadRenderScale"];
    if (value == nil)
        return 1;
    NSInteger scale = value.integerValue;
    return scale < 1 ? 1 : (scale > 4 ? 4 : scale);
}

- (void)setRenderScale:(NSInteger)renderScale {
    NSInteger clamped = renderScale < 1 ? 1 : (renderScale > 4 ? 4 : renderScale);
    [[NSUserDefaults standardUserDefaults] setInteger:clamped forKey:@"MeleePadRenderScale"];
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

- (MeleePadAspectRatioMode)aspectRatioMode {
    NSInteger mode = [[NSUserDefaults standardUserDefaults]
        integerForKey:@"MeleePadAspectRatioMode"];
    if (mode < MeleePadAspectRatioOriginal || mode > MeleePadAspectRatioFillScreen)
        return MeleePadAspectRatioOriginal;
    return (MeleePadAspectRatioMode)mode;
}

- (void)setAspectRatioMode:(MeleePadAspectRatioMode)aspectRatioMode {
    NSInteger mode = aspectRatioMode;
    if (mode < MeleePadAspectRatioOriginal || mode > MeleePadAspectRatioFillScreen)
        mode = MeleePadAspectRatioOriginal;
    [[NSUserDefaults standardUserDefaults] setInteger:mode
                                               forKey:@"MeleePadAspectRatioMode"];
}

- (BOOL)showFPSCounter {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MeleePadShowFPSCounter"];
}

- (void)setShowFPSCounter:(BOOL)showFPSCounter {
    [[NSUserDefaults standardUserDefaults] setBool:showFPSCounter
                                            forKey:@"MeleePadShowFPSCounter"];
}

- (BOOL)hideTouchControlsWhenControllerConnected {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"MeleePadHideControlsOnController"];
    return value == nil ? YES : value.boolValue;
}

- (void)setHideTouchControlsWhenControllerConnected:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"MeleePadHideControlsOnController"];
}

- (BOOL)modernCStickHorizontal {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MeleePadModernCStickHorizontal"];
}

- (void)setModernCStickHorizontal:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"MeleePadModernCStickHorizontal"];
}

- (BOOL)rightStickSmashAttacks {
    NSNumber *value = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"MeleePadRightStickSmashAttacks"];
    return value == nil ? YES : value.boolValue;
}

- (void)setRightStickSmashAttacks:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value
                                            forKey:@"MeleePadRightStickSmashAttacks"];
}

- (CGFloat)controlOpacity {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"MeleePadControlOpacity"];
    if (value == nil)
        return 0.82;
    return MAX(0.25, MIN(1.0, value.doubleValue));
}

- (void)setControlOpacity:(CGFloat)controlOpacity {
    [[NSUserDefaults standardUserDefaults] setDouble:MAX(0.25, MIN(1.0, controlOpacity))
                                              forKey:@"MeleePadControlOpacity"];
}

- (CGFloat)controlSizeScale {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"MeleePadControlSizeScale"];
    if (value == nil)
        return 1.0;
    return MAX(0.70, MIN(1.35, value.doubleValue));
}

- (void)setControlSizeScale:(CGFloat)controlSizeScale {
    [[NSUserDefaults standardUserDefaults] setDouble:MAX(0.70, MIN(1.35, controlSizeScale))
                                              forKey:@"MeleePadControlSizeScale"];
}

- (BOOL)editingControlLayout {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MeleePadEditingControlLayout"];
}

- (void)setEditingControlLayout:(BOOL)editingControlLayout {
    [[NSUserDefaults standardUserDefaults] setBool:editingControlLayout forKey:@"MeleePadEditingControlLayout"];
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
                                              forKey:@"MeleePadControlSizeScales"];
}

- (void)resetControlSizeScales {
    [_controlSizeScales removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MeleePadControlSizeScales"];
}

- (NSString *)retainedGameDataPath {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"MeleePadRetainedGameDataPath"];
}

- (void)setRetainedGameDataPath:(NSString *)retainedGameDataPath {
    if (retainedGameDataPath == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MeleePadRetainedGameDataPath"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:retainedGameDataPath
                                                  forKey:@"MeleePadRetainedGameDataPath"];
    }
}

- (NSString *)extractedGameRoot {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"MeleePadExtractedGameRoot"];
}

- (void)setExtractedGameRoot:(NSString *)extractedGameRoot {
    if (extractedGameRoot == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MeleePadExtractedGameRoot"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:extractedGameRoot
                                                  forKey:@"MeleePadExtractedGameRoot"];
    }
}

- (void)synchronize {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
