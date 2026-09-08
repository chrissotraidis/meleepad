#pragma once
#import <Foundation/Foundation.h>

// Shared catalog is also consumed by the local preparation scripts.
static inline NSArray<NSDictionary *> *MeleePadRevisions(void) {
    static NSArray *revisions;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSURL *url = [NSBundle.mainBundle URLForResource:@"MeleePadRevisions" withExtension:@"json"];
        NSData *data = url ? [NSData dataWithContentsOfURL:url] : nil;
        revisions = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : @[];
    });
    return revisions;
}

static inline NSDictionary *MeleePadRevision(NSInteger revision) {
    for (NSDictionary *entry in MeleePadRevisions())
        if ([entry[@"revision"] integerValue] == revision)
            return entry;
    return nil;
}

static inline NSInteger MeleePadRevisionAtRoot(NSString *root) {
    NSData *boot = [NSData dataWithContentsOfFile:[root stringByAppendingPathComponent:@"sys/boot.bin"]];
    if (boot.length < 8)
        return -1;
    const unsigned char *bytes = (const unsigned char *)boot.bytes;
    if (memcmp(bytes, "GALE01", 6) != 0 || bytes[6] != 0)
        return -1;
    return (bytes[7] == 0 || bytes[7] == 2) ? bytes[7] : -1;
}

static inline NSString *MeleePadRevisionLabel(NSInteger revision) {
    return revision == 2 ? @"Melee USA v1.02 · Recommended" :
           revision == 0 ? @"Melee USA v1.00" : @"No supported game selected";
}

static inline NSString *MeleePadRevisionGuidance(void) {
    return @"v1.02 is recommended for new setups and future improvements: it matches the completed decompilation and widely used Melee tools. It does not enable Slippi or guarantee higher frame rates.\n\nv1.00 remains available for existing copies and its original behavior.\n\nOnline players need the same game version and compatible MeleePad builds. Each version needs its matching locally built game module.";
}
