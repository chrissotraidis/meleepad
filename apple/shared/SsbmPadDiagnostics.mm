#import "SsbmPadDiagnostics.h"

#import <sys/sysctl.h>

static NSUInteger const SsbmPadMaximumUniqueRuntimeEvents = 64;

static NSMutableDictionary<NSString *, NSMutableDictionary *> *SsbmPadRuntimeEvents(void) {
    static NSMutableDictionary<NSString *, NSMutableDictionary *> *events;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        events = [NSMutableDictionary dictionary];
    });
    return events;
}

static NSUInteger SsbmPadDroppedRuntimeEventKinds = 0;

static NSObject *SsbmPadDiagnosticsLock(void) {
    static NSObject *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [NSObject new];
    });
    return lock;
}

static NSString *SsbmPadDiagnosticsDirectory(void) {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *root = [paths.firstObject stringByAppendingPathComponent:@"SsbmPad"];
    return [root stringByAppendingPathComponent:@"Logs"];
}

NSString *SsbmPadDiagnosticsLogPath(void) {
    return [SsbmPadDiagnosticsDirectory() stringByAppendingPathComponent:@"runtime.log"];
}

static NSString *SsbmPadDiagnosticsPreviousLogPath(void) {
    return [SsbmPadDiagnosticsDirectory() stringByAppendingPathComponent:@"runtime.previous.log"];
}

static NSString *SsbmPadRedactedString(NSString *value) {
    NSString *redacted = value ?: @"";
    NSString *temporary = NSTemporaryDirectory();
    if (temporary.length > 1)
        redacted = [redacted stringByReplacingOccurrencesOfString:temporary
                                                       withString:@"<temporary>/"];
    NSString *home = NSHomeDirectory();
    if (home.length > 0)
        redacted = [redacted stringByReplacingOccurrencesOfString:home
                                                       withString:@"<app-container>"];
    return redacted;
}

static NSString *SsbmPadSingleLine(NSString *value, NSUInteger maximumLength) {
    NSString *single = [[value ?: @"" componentsSeparatedByCharactersInSet:
        NSCharacterSet.newlineCharacterSet] componentsJoinedByString:@" "];
    single = [single stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (single.length > maximumLength)
        single = [[single substringToIndex:maximumLength] stringByAppendingString:@"…"];
    return SsbmPadRedactedString(single);
}

static NSString *SsbmPadHardwareModel(void) {
    char model[128] = {};
    size_t size = sizeof(model);
    return sysctlbyname("hw.machine", model, &size, nullptr, 0) == 0 && model[0] != '\0'
        ? @(model) : @"unknown";
}

static NSString *SsbmPadLogTimestamp(void) {
    NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
    formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime |
        NSISO8601DateFormatWithFractionalSeconds;
    return [formatter stringFromDate:NSDate.date];
}

void SsbmPadDiagnosticsStart(void) {
    @synchronized (SsbmPadDiagnosticsLock()) {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSString *directory = SsbmPadDiagnosticsDirectory();
        [fileManager createDirectoryAtPath:directory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];

        NSString *currentPath = SsbmPadDiagnosticsLogPath();
        if ([fileManager fileExistsAtPath:currentPath]) {
            NSString *previousPath = SsbmPadDiagnosticsPreviousLogPath();
            [fileManager removeItemAtPath:previousPath error:nil];
            [fileManager moveItemAtPath:currentPath toPath:previousPath error:nil];
        }
        [SsbmPadRuntimeEvents() removeAllObjects];
        SsbmPadDroppedRuntimeEventKinds = 0;
    }

    NSBundle *bundle = NSBundle.mainBundle;
    SsbmPadLog(@"session start version=%@ build=%@ os=%@",
              [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown",
              [bundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"unknown",
              NSProcessInfo.processInfo.operatingSystemVersionString);
    SsbmPadLog(@"diagnostic schema=2 hardware=%@ processors=%ld physicalMemoryMiB=%.1f",
              SsbmPadHardwareModel(), (long)NSProcessInfo.processInfo.activeProcessorCount,
              NSProcessInfo.processInfo.physicalMemory / (1024.0 * 1024.0));
}

void SsbmPadLog(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);

    message = SsbmPadRedactedString(message);

    NSLog(@"[SsbmPad] %@", message);

    NSString *line = [NSString stringWithFormat:@"%@ %@\n", SsbmPadLogTimestamp(), message];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil)
        return;

    @synchronized (SsbmPadDiagnosticsLock()) {
        NSString *path = SsbmPadDiagnosticsLogPath();
        NSFileManager *fileManager = NSFileManager.defaultManager;
        if (![fileManager fileExistsAtPath:path])
            [fileManager createFileAtPath:path contents:nil attributes:nil];
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [handle seekToEndOfFile];
        [handle writeData:data];
        [handle closeFile];
    }
}

void SsbmPadLogRuntimeEvent(NSString *severity, NSString *category, NSString *message) {
    NSString *safeSeverity = SsbmPadSingleLine(severity, 16);
    NSString *safeCategory = SsbmPadSingleLine(category, 48);
    NSString *safeMessage = SsbmPadSingleLine(message, 2000);
    NSString *signature = [NSString stringWithFormat:@"%@|%@|%@",
                           safeSeverity, safeCategory, safeMessage];
    NSUInteger count = 0;
    BOOL shouldLog = NO;
    BOOL firstDroppedKind = NO;
    @synchronized (SsbmPadDiagnosticsLock()) {
        NSMutableDictionary *event = SsbmPadRuntimeEvents()[signature];
        if (event == nil) {
            if (SsbmPadRuntimeEvents().count >= SsbmPadMaximumUniqueRuntimeEvents) {
                ++SsbmPadDroppedRuntimeEventKinds;
                firstDroppedKind = SsbmPadDroppedRuntimeEventKinds == 1;
            } else {
                event = [@{
                    @"severity": safeSeverity,
                    @"category": safeCategory,
                    @"message": safeMessage,
                    @"count": @0,
                } mutableCopy];
                SsbmPadRuntimeEvents()[signature] = event;
            }
        }
        if (event != nil) {
            count = [event[@"count"] unsignedIntegerValue] + 1;
            event[@"count"] = @(count);
            shouldLog = count == 1 || count == 10 || count == 100 || count % 1000 == 0;
        }
    }
    if (shouldLog) {
        SsbmPadLog(@"runtime event severity=%@ category=%@ count=%lu message=%@",
                  safeSeverity, safeCategory, (unsigned long)count, safeMessage);
    } else if (firstDroppedKind) {
        SsbmPadLog(@"runtime event unique-limit=%lu additional kinds will be summarized",
                  (unsigned long)SsbmPadMaximumUniqueRuntimeEvents);
    }
}

static NSString *SsbmPadRuntimeEventSummaryLocked(void) {
    NSMutableString *summary = [NSMutableString string];
    NSArray<NSString *> *signatures = [[SsbmPadRuntimeEvents() allKeys]
        sortedArrayUsingSelector:@selector(compare:)];
    if (signatures.count == 0 && SsbmPadDroppedRuntimeEventKinds == 0)
        return @"none\n";
    for (NSString *signature in signatures) {
        NSDictionary *event = SsbmPadRuntimeEvents()[signature];
        [summary appendFormat:@"severity=%@ category=%@ count=%@ message=%@\n",
            event[@"severity"], event[@"category"], event[@"count"], event[@"message"]];
    }
    if (SsbmPadDroppedRuntimeEventKinds > 0) {
        [summary appendFormat:@"additionalUniqueKinds=%lu\n",
            (unsigned long)SsbmPadDroppedRuntimeEventKinds];
    }
    return summary;
}

NSURL *SsbmPadDiagnosticsReportURL(
    NSString *reportID,
    NSDictionary<NSString *, NSString *> *reporterAnswers,
    NSString *technicalContext,
    NSError **error) {
    @synchronized (SsbmPadDiagnosticsLock()) {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSString *current = [NSString stringWithContentsOfFile:SsbmPadDiagnosticsLogPath()
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil] ?: @"unavailable\n";
        NSString *previous = [NSString stringWithContentsOfFile:SsbmPadDiagnosticsPreviousLogPath()
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil] ?: @"unavailable\n";
        NSMutableString *report = [NSMutableString string];
        [report appendString:@"SsbmPad Diagnostic Report v2\n"];
        [report appendFormat:@"reportID=%@\n", SsbmPadSingleLine(reportID, 80)];
        [report appendFormat:@"generated=%@\n", SsbmPadLogTimestamp()];
        [report appendString:@"issuesURL=https://github.com/chrissotraidis/ssbmpad/issues\n\n"];
        [report appendString:@"[Reporter Answers]\n"];
        for (NSString *key in @[@"problem", @"context", @"frequency"]) {
            NSString *value = SsbmPadSingleLine(reporterAnswers[key], 1000);
            [report appendFormat:@"%@=%@\n", key, value.length > 0 ? value : @"not provided"];
        }
        [report appendString:@"\n[Technical Context]\n"];
        [report appendString:SsbmPadRedactedString(technicalContext ?: @"unavailable")];
        if (![report hasSuffix:@"\n"])
            [report appendString:@"\n"];
        [report appendString:@"\n[Runtime Warning/Error Summary]\n"];
        [report appendString:SsbmPadRuntimeEventSummaryLocked()];
        [report appendString:@"\n[Current Session]\n"];
        [report appendString:current];
        if (![report hasSuffix:@"\n"])
            [report appendString:@"\n"];
        [report appendString:@"\n[Previous Session]\n"];
        [report appendString:previous];

        NSString *documents = [NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        if (documents.length == 0)
            documents = NSTemporaryDirectory();
        NSString *directory = [documents stringByAppendingPathComponent:@"Diagnostics"];
        if (![fileManager createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:error]) {
            return nil;
        }
        NSString *path = [directory stringByAppendingPathComponent:
                          @"Latest-SsbmPad-Diagnostic.log"];
        if (![report writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:error])
            return nil;
        return [NSURL fileURLWithPath:path];
    }
}
