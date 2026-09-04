#import "MeleePadDiagnostics.h"

#import <sys/sysctl.h>

static NSUInteger const MeleePadMaximumUniqueRuntimeEvents = 64;

static NSMutableDictionary<NSString *, NSMutableDictionary *> *MeleePadRuntimeEvents(void) {
    static NSMutableDictionary<NSString *, NSMutableDictionary *> *events;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        events = [NSMutableDictionary dictionary];
    });
    return events;
}

static NSUInteger MeleePadDroppedRuntimeEventKinds = 0;

static NSObject *MeleePadDiagnosticsLock(void) {
    static NSObject *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [NSObject new];
    });
    return lock;
}

static NSString *MeleePadDiagnosticsDirectory(void) {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *root = [paths.firstObject stringByAppendingPathComponent:@"MeleePad"];
    return [root stringByAppendingPathComponent:@"Logs"];
}

NSString *MeleePadDiagnosticsLogPath(void) {
    return [MeleePadDiagnosticsDirectory() stringByAppendingPathComponent:@"runtime.log"];
}

static NSString *MeleePadDiagnosticsPreviousLogPath(void) {
    return [MeleePadDiagnosticsDirectory() stringByAppendingPathComponent:@"runtime.previous.log"];
}

static NSString *MeleePadRedactedString(NSString *value) {
    NSString *redacted = value ?: @"";
    NSString *temporary = NSTemporaryDirectory();
    if (temporary.length > 1)
        redacted = [redacted stringByReplacingOccurrencesOfString:temporary
                                                       withString:@"<temporary>/"];
    NSString *home = NSHomeDirectory();
    if (home.length > 0)
        redacted = [redacted stringByReplacingOccurrencesOfString:home
                                                       withString:@"<app-container>"];
    // Simulator provisioning can reference a host path outside the simulated
    // app container. Scrub complete user/volume/private path tokens both when
    // they are logged and again when older logs are exported.
    static NSRegularExpression *absolutePathExpression;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        absolutePathExpression = [NSRegularExpression
            regularExpressionWithPattern:
                @"(?:/Users|/Volumes|/private|/var/folders)/[^\\s,;\\]\\)]+"
                                  options:0 error:nil];
    });
    redacted = [absolutePathExpression
        stringByReplacingMatchesInString:redacted options:0
                                   range:NSMakeRange(0, redacted.length)
                            withTemplate:@"<absolute-path>"];

    // Diagnostics are user-shareable. Keep common online-play credentials and
    // identifiers out even if a future call site accidentally includes one.
    // Player names are not globally recognizable, so call sites must also avoid
    // logging them; the keyed pattern below is a final guard for named fields.
    static NSArray<NSDictionary<NSString *, id> *> *privacyPatterns;
    static dispatch_once_t privacyOnceToken;
    dispatch_once(&privacyOnceToken, ^{
        NSRegularExpression *(^expression)(NSString *) = ^NSRegularExpression *(NSString *pattern) {
            return [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        };
        privacyPatterns = @[
            @{@"expression": expression(@"(?i)(bearer\\s+)[A-Za-z0-9._~+/=-]+"),
              @"replacement": @"$1<redacted>"},
            @{@"expression": expression(@"(?i)((?:room[ _-]?code|traversal[ _-]?code|token|nickname|display[ _-]?name|host[ _-]?address)\\s*[=:]\\s*)[^\\s,;\\]\\)]+"),
              @"replacement": @"$1<redacted>"},
            @{@"expression": expression(@"\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b"),
              @"replacement": @"<ip-address>"},
        ];
    });
    for (NSDictionary<NSString *, id> *pattern in privacyPatterns) {
        NSRegularExpression *expression = pattern[@"expression"];
        redacted = [expression stringByReplacingMatchesInString:redacted options:0
            range:NSMakeRange(0, redacted.length) withTemplate:pattern[@"replacement"]];
    }
    return redacted;
}

static NSString *MeleePadSingleLine(NSString *value, NSUInteger maximumLength) {
    NSString *single = [[value ?: @"" componentsSeparatedByCharactersInSet:
        NSCharacterSet.newlineCharacterSet] componentsJoinedByString:@" "];
    single = [single stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (single.length > maximumLength)
        single = [[single substringToIndex:maximumLength] stringByAppendingString:@"…"];
    return MeleePadRedactedString(single);
}

static NSString *MeleePadHardwareModel(void) {
    char model[128] = {};
    size_t size = sizeof(model);
    return sysctlbyname("hw.machine", model, &size, nullptr, 0) == 0 && model[0] != '\0'
        ? @(model) : @"unknown";
}

static NSString *MeleePadLogTimestamp(void) {
    NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
    formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime |
        NSISO8601DateFormatWithFractionalSeconds;
    return [formatter stringFromDate:NSDate.date];
}

void MeleePadDiagnosticsStart(void) {
    @synchronized (MeleePadDiagnosticsLock()) {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSString *directory = MeleePadDiagnosticsDirectory();
        [fileManager createDirectoryAtPath:directory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];

        NSString *currentPath = MeleePadDiagnosticsLogPath();
        if ([fileManager fileExistsAtPath:currentPath]) {
            NSString *previousPath = MeleePadDiagnosticsPreviousLogPath();
            [fileManager removeItemAtPath:previousPath error:nil];
            [fileManager moveItemAtPath:currentPath toPath:previousPath error:nil];
        }
        [MeleePadRuntimeEvents() removeAllObjects];
        MeleePadDroppedRuntimeEventKinds = 0;
    }

    NSBundle *bundle = NSBundle.mainBundle;
    MeleePadLog(@"session start version=%@ build=%@ os=%@",
              [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown",
              [bundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"unknown",
              NSProcessInfo.processInfo.operatingSystemVersionString);
    MeleePadLog(@"diagnostic schema=2 hardware=%@ processors=%ld physicalMemoryMiB=%.1f",
              MeleePadHardwareModel(), (long)NSProcessInfo.processInfo.activeProcessorCount,
              NSProcessInfo.processInfo.physicalMemory / (1024.0 * 1024.0));
}

void MeleePadLog(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);

    message = MeleePadRedactedString(message);

    NSLog(@"[MeleePad] %@", message);

    NSString *line = [NSString stringWithFormat:@"%@ %@\n", MeleePadLogTimestamp(), message];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil)
        return;

    @synchronized (MeleePadDiagnosticsLock()) {
        NSString *path = MeleePadDiagnosticsLogPath();
        NSFileManager *fileManager = NSFileManager.defaultManager;
        if (![fileManager fileExistsAtPath:path])
            [fileManager createFileAtPath:path contents:nil attributes:nil];
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [handle seekToEndOfFile];
        [handle writeData:data];
        [handle closeFile];
    }
}

void MeleePadLogRuntimeEvent(NSString *severity, NSString *category, NSString *message) {
    NSString *safeSeverity = MeleePadSingleLine(severity, 16);
    NSString *safeCategory = MeleePadSingleLine(category, 48);
    NSString *safeMessage = MeleePadSingleLine(message, 2000);
    NSString *signature = [NSString stringWithFormat:@"%@|%@|%@",
                           safeSeverity, safeCategory, safeMessage];
    NSUInteger count = 0;
    BOOL shouldLog = NO;
    BOOL firstDroppedKind = NO;
    @synchronized (MeleePadDiagnosticsLock()) {
        NSMutableDictionary *event = MeleePadRuntimeEvents()[signature];
        if (event == nil) {
            if (MeleePadRuntimeEvents().count >= MeleePadMaximumUniqueRuntimeEvents) {
                ++MeleePadDroppedRuntimeEventKinds;
                firstDroppedKind = MeleePadDroppedRuntimeEventKinds == 1;
            } else {
                event = [@{
                    @"severity": safeSeverity,
                    @"category": safeCategory,
                    @"message": safeMessage,
                    @"count": @0,
                } mutableCopy];
                MeleePadRuntimeEvents()[signature] = event;
            }
        }
        if (event != nil) {
            count = [event[@"count"] unsignedIntegerValue] + 1;
            event[@"count"] = @(count);
            shouldLog = count == 1 || count == 10 || count == 100 || count % 1000 == 0;
        }
    }
    if (shouldLog) {
        MeleePadLog(@"runtime event severity=%@ category=%@ count=%lu message=%@",
                  safeSeverity, safeCategory, (unsigned long)count, safeMessage);
    } else if (firstDroppedKind) {
        MeleePadLog(@"runtime event unique-limit=%lu additional kinds will be summarized",
                  (unsigned long)MeleePadMaximumUniqueRuntimeEvents);
    }
}

static NSString *MeleePadRuntimeEventSummaryLocked(void) {
    NSMutableString *summary = [NSMutableString string];
    NSArray<NSString *> *signatures = [[MeleePadRuntimeEvents() allKeys]
        sortedArrayUsingSelector:@selector(compare:)];
    if (signatures.count == 0 && MeleePadDroppedRuntimeEventKinds == 0)
        return @"none\n";
    for (NSString *signature in signatures) {
        NSDictionary *event = MeleePadRuntimeEvents()[signature];
        [summary appendFormat:@"severity=%@ category=%@ count=%@ message=%@\n",
            event[@"severity"], event[@"category"], event[@"count"], event[@"message"]];
    }
    if (MeleePadDroppedRuntimeEventKinds > 0) {
        [summary appendFormat:@"additionalUniqueKinds=%lu\n",
            (unsigned long)MeleePadDroppedRuntimeEventKinds];
    }
    return summary;
}

NSURL *MeleePadDiagnosticsReportURL(
    NSString *reportID,
    NSDictionary<NSString *, NSString *> *reporterAnswers,
    NSString *technicalContext,
    NSError **error) {
    @synchronized (MeleePadDiagnosticsLock()) {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSString *current = [NSString stringWithContentsOfFile:MeleePadDiagnosticsLogPath()
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil] ?: @"unavailable\n";
        NSString *previous = [NSString stringWithContentsOfFile:MeleePadDiagnosticsPreviousLogPath()
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil] ?: @"unavailable\n";
        NSMutableString *report = [NSMutableString string];
        [report appendString:@"MeleePad Diagnostic Report v2\n"];
        [report appendFormat:@"reportID=%@\n", MeleePadSingleLine(reportID, 80)];
        [report appendFormat:@"generated=%@\n", MeleePadLogTimestamp()];
        [report appendString:@"issuesURL=https://github.com/chrissotraidis/meleepad/issues\n\n"];
        [report appendString:@"[Reporter Answers]\n"];
        for (NSString *key in @[@"problem", @"context", @"frequency"]) {
            NSString *value = MeleePadSingleLine(reporterAnswers[key], 1000);
            [report appendFormat:@"%@=%@\n", key, value.length > 0 ? value : @"not provided"];
        }
        [report appendString:@"\n[Technical Context]\n"];
        [report appendString:MeleePadRedactedString(technicalContext ?: @"unavailable")];
        if (![report hasSuffix:@"\n"])
            [report appendString:@"\n"];
        [report appendString:@"\n[Runtime Warning/Error Summary]\n"];
        [report appendString:MeleePadRuntimeEventSummaryLocked()];
        [report appendString:@"\n[Current Session]\n"];
        [report appendString:MeleePadRedactedString(current)];
        if (![report hasSuffix:@"\n"])
            [report appendString:@"\n"];
        [report appendString:@"\n[Previous Session]\n"];
        [report appendString:MeleePadRedactedString(previous)];

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
                          @"Latest-MeleePad-Diagnostic.log"];
        if (![report writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:error])
            return nil;
        return [NSURL fileURLWithPath:path];
    }
}
