#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/* Root view controller: hosts the Metal game surface and the MeleePad overlay
 * (three-dot menu, render resolution, touch controls). */
@interface MeleePadGameViewController : UIViewController

/* Forward iOS application lifecycle events to the active game runtime. */
- (void)pauseRuntimeForApplicationLifecycle;
- (void)resumeRuntimeForApplicationLifecycle;

@end

NS_ASSUME_NONNULL_END
