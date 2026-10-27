#import <Foundation/Foundation.h>

#include <cassert>
#include <iostream>
#include <signal.h>
#include <sys/resource.h>

#import "MeleePadDiagnostics.h"

static void TestLogWriteFailure(void) {
    NSString *path = MeleePadDiagnosticsLogPath();
    NSData *before = [NSData dataWithContentsOfFile:path];
    assert(before != nil);
    struct rlimit original;
    assert(getrlimit(RLIMIT_FSIZE, &original) == 0);
    struct rlimit limited = original;
    limited.rlim_cur = before.length;
    auto previousSignalHandler = signal(SIGXFSZ, SIG_IGN);
    assert(previousSignalHandler != SIG_ERR);
    assert(setrlimit(RLIMIT_FSIZE, &limited) == 0);
    bool threw = false;
    @try {
        // Force a real filesystem write failure without filling the disk.
        // Reporting a save failure must not itself terminate the app.
        MeleePadLogRuntimeEvent(@"error", @"EXI", @"save-write failure sentinel");
    } @catch (NSException *exception) {
        threw = true;
    } @finally {
        assert(setrlimit(RLIMIT_FSIZE, &original) == 0);
        assert(signal(SIGXFSZ, previousSignalHandler) != SIG_ERR);
    }
    assert(!threw);
    assert([[NSData dataWithContentsOfFile:path] isEqualToData:before]);
    MeleePadLog(@"logging recovered sentinel");
    NSString *after = [NSString stringWithContentsOfFile:path
                                              encoding:NSUTF8StringEncoding error:nil];
    assert([after containsString:@"logging recovered sentinel"]);
}

int main(void) {
    @autoreleasepool {
        MeleePadDiagnosticsStart();
        MeleePadLog(@"previous session sentinel");
        MeleePadDiagnosticsStart();
        MeleePadLog(@"current session sentinel");
        NSString *home = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/MeleePad"];
        NSString *temporary = [NSTemporaryDirectory() stringByAppendingPathComponent:@"import.iso"];
        MeleePadLog(@"private paths home=%@ temporary=%@", home, temporary);
        MeleePadLog(@"provisioned root=/Users/external-test/PrivateGame/main.dol");
        MeleePadLog(@"online privacy roomCode=deadbeef token=secret-token nickname=SecretPlayer host_address=198.51.100.42 Authorization=Bearer abc.def.ghi");
        MeleePadLog(@"online network endpoint 203.0.113.17 unavailable");
        for (NSUInteger index = 0; index < 11; ++index)
            MeleePadLogRuntimeEvent(@"warning", @"host-gpu", @"repeated sentinel");

        NSError *error = nil;
        NSString *contents = [NSString stringWithContentsOfFile:MeleePadDiagnosticsLogPath()
                                                        encoding:NSUTF8StringEncoding
                                                           error:&error];
        assert(contents != nil && error == nil);
        assert([contents containsString:@"current session sentinel"]);
        assert(![contents containsString:@"previous session sentinel"]);
        assert(![contents containsString:NSHomeDirectory()]);
        assert(![contents containsString:NSTemporaryDirectory()]);
        assert(![contents containsString:@"/Users/external-test"]);
        assert(![contents containsString:@"PrivateGame"]);
        assert([contents containsString:@"provisioned root=<absolute-path>"]);
        assert(![contents containsString:@"deadbeef"]);
        assert(![contents containsString:@"secret-token"]);
        assert(![contents containsString:@"SecretPlayer"]);
        assert(![contents containsString:@"198.51.100.42"]);
        assert(![contents containsString:@"203.0.113.17"]);
        assert(![contents containsString:@"abc.def.ghi"]);
        assert([contents containsString:@"roomCode=<redacted>"]);
        assert([contents containsString:@"<ip-address>"]);

        TestLogWriteFailure();

        NSDictionary *answers = @{
            @"problem": @"The picture warped after entering combat.",
            @"context": @"Classic mode\nthen took a screenshot",
            @"frequency": @"Once",
        };
        NSURL *url = MeleePadDiagnosticsReportURL(
            @"SB-TEST123", answers, [NSString stringWithFormat:@"private=%@", home], &error);
        assert(url != nil && error == nil);
        assert([url.lastPathComponent isEqualToString:@"Latest-MeleePad-Diagnostic.log"]);
        NSString *report = [NSString stringWithContentsOfURL:url
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
        assert(report != nil && error == nil);
        assert([report containsString:@"MeleePad Diagnostic Report v2"]);
        assert([report containsString:@"issuesURL=https://github.com/chrissotraidis/meleepad/issues"]);
        assert([report containsString:@"category=host-gpu count=11"]);
        assert([report containsString:@"category=EXI count=1 message=save-write failure sentinel"]);
        assert(![report containsString:NSHomeDirectory()]);
        assert(![report containsString:NSTemporaryDirectory()]);
        assert(![report containsString:@"/Users/external-test"]);
        assert(![report containsString:@"PrivateGame"]);
        std::cout << "MeleePad diagnostic privacy tests passed\n";
    }
    return 0;
}
