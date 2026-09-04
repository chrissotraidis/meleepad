#import <Foundation/Foundation.h>

#include <cassert>
#include <iostream>

#import "MeleePadDiagnostics.h"

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
        assert(![report containsString:NSHomeDirectory()]);
        assert(![report containsString:NSTemporaryDirectory()]);
        assert(![report containsString:@"/Users/external-test"]);
        assert(![report containsString:@"PrivateGame"]);
        std::cout << "MeleePad diagnostic privacy tests passed\n";
    }
    return 0;
}
