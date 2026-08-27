// Host-only macOS preflight for Metal's actual drawable presentation cadence.
// This does not link Dolphin, run emulated code, or alter product settings.

#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <numeric>
#include <vector>

namespace
{
double Percentile(std::vector<double> values, double fraction)
{
  std::sort(values.begin(), values.end());
  const double position = fraction * static_cast<double>(values.size() - 1);
  const auto lower = static_cast<std::size_t>(std::floor(position));
  const auto upper = static_cast<std::size_t>(std::ceil(position));
  const double weight = position - static_cast<double>(lower);
  return values[lower] * (1.0 - weight) + values[upper] * weight;
}
}  // namespace

int main(int argc, char** argv)
{
  const int samples = argc >= 2 ? std::atoi(argv[1]) : 600;
  const int minimum_duration_us = argc >= 3 ? std::atoi(argv[2]) : 16'667;
  if (samples < 100 || minimum_duration_us < 0 || minimum_duration_us > 100'000)
  {
    std::fprintf(stderr,
                 "usage: g5_metal_present_preflight [samples>=100] "
                 "[minimum-duration-us 0..100000]\n");
    return 2;
  }

  @autoreleasepool
  {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLCommandQueue> queue = [device newCommandQueue];
    if (device == nil || queue == nil)
    {
      std::fprintf(stderr, "Metal device or command queue unavailable\n");
      return 1;
    }

    CAMetalLayer* layer = [CAMetalLayer layer];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;
    layer.drawableSize = CGSizeMake(64, 64);
    layer.maximumDrawableCount = 3;
    layer.displaySyncEnabled = YES;

    NSRect frame = NSMakeRect(24, 24, 64, 64);
    NSView* view = [[NSView alloc] initWithFrame:frame];
    view.wantsLayer = YES;
    view.layer = layer;
    NSWindow* window =
        [[NSWindow alloc] initWithContentRect:frame
                                   styleMask:NSWindowStyleMaskBorderless
                                     backing:NSBackingStoreBuffered
                                       defer:NO];
    window.releasedWhenClosed = NO;
    window.contentView = view;
    [window orderFrontRegardless];
    [[NSRunLoop currentRunLoop]
        runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    constexpr int warmup = 30;
    const int total_frames = samples + warmup + 1;
    std::vector<double> all_presented_times(total_frames, 0.0);
    double* const presented_data = all_presented_times.data();
    dispatch_group_t presented_group = dispatch_group_create();
    const CFTimeInterval minimum_duration =
        static_cast<CFTimeInterval>(minimum_duration_us) / 1'000'000.0;

    for (int index = 0; index < total_frames; ++index)
    {
      @autoreleasepool
      {
        id<CAMetalDrawable> drawable = [layer nextDrawable];
        if (drawable == nil)
        {
          std::fprintf(stderr, "nextDrawable returned nil at frame %d\n", index);
          return 1;
        }

        MTLRenderPassDescriptor* pass = [MTLRenderPassDescriptor renderPassDescriptor];
        pass.colorAttachments[0].texture = drawable.texture;
        pass.colorAttachments[0].loadAction = MTLLoadActionClear;
        pass.colorAttachments[0].storeAction = MTLStoreActionStore;
        pass.colorAttachments[0].clearColor =
            MTLClearColorMake((index & 1) ? 0.1 : 0.2, 0.1, 0.2, 1.0);

        id<MTLCommandBuffer> command_buffer = [queue commandBuffer];
        id<MTLRenderCommandEncoder> encoder =
            [command_buffer renderCommandEncoderWithDescriptor:pass];
        [encoder endEncoding];

        dispatch_group_enter(presented_group);
        [drawable addPresentedHandler:^(id<MTLDrawable> value) {
          presented_data[index] = value.presentedTime;
          dispatch_group_leave(presented_group);
        }];
        if (minimum_duration_us == 0)
          [command_buffer presentDrawable:drawable];
        else
          [command_buffer presentDrawable:drawable afterMinimumDuration:minimum_duration];
        [command_buffer commit];
      }
    }

    if (dispatch_group_wait(presented_group,
                            dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)) != 0)
    {
      std::fprintf(stderr, "presentation callback timeout\n");
      return 1;
    }

    [window orderOut:nil];
    [window close];

    std::vector<double> presented_times(all_presented_times.begin() + warmup,
                                        all_presented_times.end());
    const int dropped = static_cast<int>(std::count(presented_times.begin(),
                                                    presented_times.end(), 0.0));
    if (dropped != 0)
    {
      std::fprintf(stderr, "dropped=%d measured=%zu\n", dropped, presented_times.size());
      return 1;
    }

    std::vector<double> intervals_ms;
    intervals_ms.reserve(samples);
    for (std::size_t index = 1; index < presented_times.size(); ++index)
      intervals_ms.push_back((presented_times[index] - presented_times[index - 1]) * 1000.0);

    const double mean =
        std::accumulate(intervals_ms.begin(), intervals_ms.end(), 0.0) / intervals_ms.size();
    const std::size_t at_or_below =
        std::count_if(intervals_ms.begin(), intervals_ms.end(), [](double value) {
          return value <= 16.7;
        });
    std::printf(
        "samples=%zu minimum_duration_us=%d mean=%.6f median=%.6f p95=%.6f p99=%.6f "
        "worst=%.6f le16.7=%.3f%% dropped=%d\n",
        intervals_ms.size(), minimum_duration_us, mean, Percentile(intervals_ms, 0.50),
        Percentile(intervals_ms, 0.95), Percentile(intervals_ms, 0.99),
        *std::max_element(intervals_ms.begin(), intervals_ms.end()),
        100.0 * static_cast<double>(at_or_below) / intervals_ms.size(), dropped);
  }
  return 0;
}
