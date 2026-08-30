#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* Extracts a GameCube disc image into the extracted layout the compatibility
 * runtime boots from (sys/ + files/). Runs on a background queue. */
@interface SsbmPadDiscExtractor : NSObject

+ (void)extractImageAtPath:(NSString *)imagePath
              toDirectory:(NSString *)destination
                  progress:(nullable void (^)(NSString *status, double fraction))progress
                completion:(void (^)(BOOL ok, NSString *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
