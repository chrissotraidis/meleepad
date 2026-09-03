#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* Starts the persistent runtime log and rotates it when it grows beyond 1 MB.
 * The log lives in Library/Application Support/MeleePad/Logs/runtime.log so it
 * survives app relaunches and can be retrieved with devicectl. */
FOUNDATION_EXPORT void MeleePadDiagnosticsStart(void);

/* Writes one timestamped line to both the unified device log and MeleePad's
 * persistent runtime log. Intended for low-frequency lifecycle breadcrumbs,
 * not per-frame tracing. */
FOUNDATION_EXPORT void MeleePadLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/* Records a warning/error emitted by the embedded runtime. Repeated identical
 * events are counted and rate-limited so a failure cannot flood the log. */
FOUNDATION_EXPORT void MeleePadLogRuntimeEvent(
    NSString *severity, NSString *category, NSString *message);

FOUNDATION_EXPORT NSString *MeleePadDiagnosticsLogPath(void);

/* Builds the single privacy-reviewed file used by the guided problem-report
 * flow. Reporter answers and current technical context lead the file, followed
 * by bounded runtime-event summaries and the current/previous app sessions. */
FOUNDATION_EXPORT NSURL *_Nullable MeleePadDiagnosticsReportURL(
    NSString *reportID,
    NSDictionary<NSString *, NSString *> *reporterAnswers,
    NSString *technicalContext,
    NSError **error);

NS_ASSUME_NONNULL_END
