#import "MeleePadSettings.h"
#import <Foundation/Foundation.h>

int main() {
    @autoreleasepool {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *key = @"MeleePadSlippiInputDelayFrames";
        id original = [defaults objectForKey:key];
        [defaults removeObjectForKey:key];
        MeleePadSettings *settings = [MeleePadSettings sharedSettings];
        BOOL valid = settings.slippiInputDelayFrames == 2;
        settings.slippiInputDelayFrames = 0;
        valid &= settings.slippiInputDelayFrames == 1;
        settings.slippiInputDelayFrames = 9;
        valid &= settings.slippiInputDelayFrames == 4;
        settings.slippiInputDelayFrames = 3;
        [settings synchronize];
        valid &= settings.slippiInputDelayFrames == 3;
        if (original != nil)
            [defaults setObject:original forKey:key];
        else
            [defaults removeObjectForKey:key];
        [defaults synchronize];
        if (!valid) {
            NSLog(@"Slippi input-delay defaults or clamping failed");
            return 1;
        }
        NSLog(@"Slippi input-delay settings passed");
        return 0;
    }
}
