#import <Foundation/Foundation.h>

#include <cassert>
#include <iostream>

#import "SsbmPadDiagnostics.h"

int main(void) {
    @autoreleasepool {
        SsbmPadDiagnosticsStart();
        SsbmPadLog(@"previous session sentinel");
        SsbmPadDiagnosticsStart();
        SsbmPadLog(@"current session sentinel");
        NSString *home = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/SsbmPad"];
        NSString *temporary = [NSTemporaryDirectory() stringByAppendingPathComponent:@"import.iso"];
        SsbmPadLog(@"private paths home=%@ temporary=%@", home, temporary);
        SsbmPadLog(@"provisioned root=/Users/external-test/PrivateGame/main.dol");
        for (NSUInteger index = 0; index < 11; ++index)
            SsbmPadLogRuntimeEvent(@"warning", @"host-gpu", @"repeated sentinel");

        NSError *error = nil;
        NSString *contents = [NSString stringWithContentsOfFile:SsbmPadDiagnosticsLogPath()
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

        NSDictionary *answers = @{
            @"problem": @"The picture warped after entering combat.",
            @"context": @"Classic mode\nthen took a screenshot",
            @"frequency": @"Once",
        };
        NSURL *url = SsbmPadDiagnosticsReportURL(
            @"SB-TEST123", answers, [NSString stringWithFormat:@"private=%@", home], &error);
        assert(url != nil && error == nil);
        assert([url.lastPathComponent isEqualToString:@"Latest-SsbmPad-Diagnostic.log"]);
        NSString *report = [NSString stringWithContentsOfURL:url
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
        assert(report != nil && error == nil);
        assert([report containsString:@"SsbmPad Diagnostic Report v2"]);
        assert([report containsString:@"issuesURL=https://github.com/chrissotraidis/ssbmpad/issues"]);
        assert([report containsString:@"category=host-gpu count=11"]);
        assert(![report containsString:NSHomeDirectory()]);
        assert(![report containsString:NSTemporaryDirectory()]);
        assert(![report containsString:@"/Users/external-test"]);
        assert(![report containsString:@"PrivateGame"]);
        std::cout << "SsbmPad diagnostic privacy tests passed\n";
    }
    return 0;
}
