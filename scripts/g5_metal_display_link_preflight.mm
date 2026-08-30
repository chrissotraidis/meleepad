#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <mutex>
#include <numeric>
#include <vector>

namespace
{
double Percentile(std::vector<double> values, double fraction)
{
  std::sort(values.begin(), values.end());
  const auto index = static_cast<std::size_t>(std::ceil(fraction * values.size())) - 1;
  return values[index];
}

struct PresentedTimes
{
  std::mutex mutex;
  std::vector<double> values;
};
}

@interface DisplayLinkDelegate : NSObject <CAMetalDisplayLinkDelegate>
@property(nonatomic, strong) id<MTLCommandQueue> queue;
@property(nonatomic, assign) CAMetalDisplayLink* link;
@property(nonatomic, assign) NSInteger totalCallbacks;
@property(nonatomic, assign) NSInteger callbackCount;
@property(nonatomic, assign) PresentedTimes* presentedTimes;
@property(nonatomic, assign) std::vector<double>* callbackTimes;
@property(nonatomic, assign) std::vector<double>* targetTimes;
@property(nonatomic, assign) std::vector<double>* targetPresentationTimes;
@end

@implementation DisplayLinkDelegate
- (void)metalDisplayLink:(CAMetalDisplayLink*)link
             needsUpdate:(CAMetalDisplayLinkUpdate*)update
{
  self.callbackTimes->push_back(CACurrentMediaTime());
  self.targetTimes->push_back(update.targetTimestamp);
  self.targetPresentationTimes->push_back(update.targetPresentationTimestamp);

  id<MTLCommandBuffer> commandBuffer = [self.queue commandBuffer];
  MTLRenderPassDescriptor* pass = [MTLRenderPassDescriptor renderPassDescriptor];
  pass.colorAttachments[0].texture = update.drawable.texture;
  pass.colorAttachments[0].loadAction = MTLLoadActionClear;
  pass.colorAttachments[0].storeAction = MTLStoreActionStore;
  const double phase = std::fmod(static_cast<double>(self.callbackCount), 120.0) / 120.0;
  pass.colorAttachments[0].clearColor = MTLClearColorMake(phase, 1.0 - phase, 0.25, 1.0);
  id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:pass];
  [encoder endEncoding];

  PresentedTimes* const storage = self.presentedTimes;
  [update.drawable addPresentedHandler:^(id<MTLDrawable> drawable) {
    std::lock_guard<std::mutex> guard(storage->mutex);
    storage->values.push_back(drawable.presentedTime);
  }];
  [commandBuffer presentDrawable:update.drawable];
  [commandBuffer commit];

  self.callbackCount += 1;
  if (self.callbackCount >= self.totalCallbacks)
  {
    link.paused = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
                     [NSApp stop:nil];
                     NSEvent* event = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
                                                         location:NSZeroPoint
                                                    modifierFlags:0
                                                        timestamp:0
                                                     windowNumber:0
                                                          context:nil
                                                          subtype:0
                                                            data1:0
                                                            data2:0];
                     [NSApp postEvent:event atStart:NO];
                   });
  }
}
@end

int main(int argc, const char* argv[])
{
  @autoreleasepool
  {
    if (argc != 4)
    {
      std::fprintf(stderr, "usage: %s measured_callbacks warmup_callbacks requested_fps\n", argv[0]);
      return 2;
    }

    const int measured = std::atoi(argv[1]);
    const int warmup = std::atoi(argv[2]);
    const double requestedFps = std::atof(argv[3]);
    if (measured < 100 || warmup < 1 || requestedFps <= 0.0)
    {
      std::fprintf(stderr, "invalid arguments\n");
      return 2;
    }

    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device)
    {
      std::fprintf(stderr, "no Metal device\n");
      return 1;
    }

    NSWindow* window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(40, 40, 64, 64)
                  styleMask:NSWindowStyleMaskBorderless
                    backing:NSBackingStoreBuffered
                      defer:NO];
    NSView* view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
    CAMetalLayer* layer = [CAMetalLayer layer];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;
    layer.drawableSize = CGSizeMake(64, 64);
    layer.displaySyncEnabled = YES;
    view.wantsLayer = YES;
    view.layer = layer;
    window.contentView = view;
    [window orderFrontRegardless];

    std::vector<double> callbackTimes;
    std::vector<double> targetTimes;
    std::vector<double> targetPresentationTimes;
    PresentedTimes presentedTimes;
    const int total = warmup + measured + 1;
    callbackTimes.reserve(total);
    targetTimes.reserve(total);
    targetPresentationTimes.reserve(total);

    DisplayLinkDelegate* delegate = [DisplayLinkDelegate new];
    delegate.queue = [device newCommandQueue];
    delegate.totalCallbacks = total;
    delegate.callbackCount = 0;
    delegate.presentedTimes = &presentedTimes;
    delegate.callbackTimes = &callbackTimes;
    delegate.targetTimes = &targetTimes;
    delegate.targetPresentationTimes = &targetPresentationTimes;

    CAMetalDisplayLink* link = [[CAMetalDisplayLink alloc] initWithMetalLayer:layer];
    delegate.link = link;
    link.delegate = delegate;
    link.preferredFrameLatency = 1.0f;
    const float fps = static_cast<float>(requestedFps);
    link.preferredFrameRateRange = CAFrameRateRangeMake(fps, fps, fps);
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [NSApp run];
    [link invalidate];

    std::vector<double> presented;
    {
      std::lock_guard<std::mutex> guard(presentedTimes.mutex);
      presented = presentedTimes.values;
    }
    presented.erase(std::remove(presented.begin(), presented.end(), 0.0), presented.end());

    auto intervals = [warmup](const std::vector<double>& values) {
      std::vector<double> result;
      for (std::size_t i = static_cast<std::size_t>(warmup + 1); i < values.size(); ++i)
        result.push_back((values[i] - values[i - 1]) * 1000.0);
      return result;
    };

    const auto callbacks = intervals(callbackTimes);
    const auto targets = intervals(targetTimes);
    const auto targetPresentations = intervals(targetPresentationTimes);
    const auto actualPresentations = intervals(presented);

    std::size_t sourceRepeats = 0;
    std::size_t sourceJumps = 0;
    const double sourceEpoch = targetPresentationTimes.front();
    long long previousSourceFrame = static_cast<long long>(std::floor(
        (targetPresentationTimes[static_cast<std::size_t>(warmup)] - sourceEpoch) *
            requestedFps +
        1e-6));
    for (std::size_t i = static_cast<std::size_t>(warmup + 1);
         i < targetPresentationTimes.size(); ++i)
    {
      const long long sourceFrame = static_cast<long long>(std::floor(
          (targetPresentationTimes[i] - sourceEpoch) * requestedFps + 1e-6));
      if (sourceFrame == previousSourceFrame)
        sourceRepeats += 1;
      else if (sourceFrame > previousSourceFrame + 1)
        sourceJumps += static_cast<std::size_t>(sourceFrame - previousSourceFrame - 1);
      previousSourceFrame = sourceFrame;
    }

    auto report = [](const char* name, const std::vector<double>& values) {
      if (values.empty())
      {
        std::printf("%s count=0\n", name);
        return;
      }
      const double mean = std::accumulate(values.begin(), values.end(), 0.0) / values.size();
      std::printf(
          "%s count=%zu mean=%.6f p50=%.6f p95=%.6f p99=%.6f worst=%.6f "
          "le16.7=%zu gt20=%zu\n",
          name, values.size(), mean, Percentile(values, 0.50), Percentile(values, 0.95),
          Percentile(values, 0.99), *std::max_element(values.begin(), values.end()),
          std::count_if(values.begin(), values.end(), [](double value) { return value <= 16.7; }),
          std::count_if(values.begin(), values.end(), [](double value) { return value > 20.0; }));
    };

    std::printf("requested_fps=%.9f callbacks=%zu presented_nonzero=%zu\n", requestedFps,
                callbackTimes.size(), presented.size());
    std::printf("source_model intervals=%d repeated_source_callbacks=%zu skipped_source_frames=%zu\n",
                measured, sourceRepeats, sourceJumps);
    report("callback", callbacks);
    report("target", targets);
    report("target_presentation", targetPresentations);
    report("actual_presentation", actualPresentations);
    return callbacks.size() == static_cast<std::size_t>(measured) &&
                   targets.size() == static_cast<std::size_t>(measured) &&
                   targetPresentations.size() == static_cast<std::size_t>(measured) &&
                   actualPresentations.size() >= static_cast<std::size_t>(measured - 2)
               ? 0
               : 1;
  }
}
