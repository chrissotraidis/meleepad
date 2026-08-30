#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* Starts the persistent runtime log and rotates it when it grows beyond 1 MB.
 * The log lives in Library/Application Support/SsbmPad/Logs/runtime.log so it
 * survives app relaunches and can be retrieved with devicectl. */
FOUNDATION_EXPORT void SsbmPadDiagnosticsStart(void);

/* Writes one timestamped line to both the unified device log and SsbmPad's
 * persistent runtime log. Intended for low-frequency lifecycle breadcrumbs,
 * not per-frame tracing. */
FOUNDATION_EXPORT void SsbmPadLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/* Records a warning/error emitted by the embedded runtime. Repeated identical
 * events are counted and rate-limited so a failure cannot flood the log. */
FOUNDATION_EXPORT void SsbmPadLogRuntimeEvent(
    NSString *severity, NSString *category, NSString *message);

FOUNDATION_EXPORT NSString *SsbmPadDiagnosticsLogPath(void);

/* Builds the single privacy-reviewed file used by the guided problem-report
 * flow. Reporter answers and current technical context lead the file, followed
 * by bounded runtime-event summaries and the current/previous app sessions. */
FOUNDATION_EXPORT NSURL *_Nullable SsbmPadDiagnosticsReportURL(
    NSString *reportID,
    NSDictionary<NSString *, NSString *> *reporterAnswers,
    NSString *technicalContext,
    NSError **error);

NS_ASSUME_NONNULL_END
