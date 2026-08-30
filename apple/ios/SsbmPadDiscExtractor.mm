#import "SsbmPadDiscExtractor.h"

#include <atomic>
#include <filesystem>
#include <string>

#include "DiscIO/DiscExtractor.h"
#include "DiscIO/Filesystem.h"
#include "DiscIO/Volume.h"

namespace fs = std::filesystem;

@implementation SsbmPadDiscExtractor

+ (void)extractImageAtPath:(NSString *)imagePath
              toDirectory:(NSString *)destination
                  progress:(void (^)(NSString *, double))progress
                completion:(void (^)(BOOL, NSString *_Nullable))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        if (progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(@"Opening disc image", 0.0);
            });
        }

        std::unique_ptr<DiscIO::Volume> volume =
            DiscIO::CreateVolume(imagePath.fileSystemRepresentation);
        if (!volume) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, @"Dolphin could not open the disc image.");
            });
            return;
        }

        const DiscIO::Partition partition = volume->GetGamePartition();
        const DiscIO::FileSystem *filesystem = volume->GetFileSystem(partition);
        if (!filesystem || !filesystem->IsValid()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, @"Dolphin could not read the game filesystem.");
            });
            return;
        }

        std::error_code ec;
        fs::path root = destination.fileSystemRepresentation;
        fs::create_directories(root / "files", ec);
        if (ec) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, @"Could not create the extraction directory.");
            });
            return;
        }

        if (progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(@"Extracting system data", 0.05);
            });
        }
        if (!DiscIO::ExportSystemData(*volume, partition, root.string())) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, @"System-data extraction failed.");
            });
            return;
        }

        const u64 total = std::max<u64>(1, filesystem->GetRoot().GetTotalChildren());
        std::atomic<u64> completed{0};
        if (progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(@"Extracting game files", 0.10);
            });
        }
        DiscIO::ExportDirectory(
            *volume, partition, filesystem->GetRoot(), true, "",
            (root / "files").string(),
            [&completed, total, progress](const std::string &path) {
                ++completed;
                if (progress) {
                    double fraction = 0.10 + 0.85 * (double)completed.load() / (double)total;
                    NSString *status = @(path.c_str());
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progress(status, fraction);
                    });
                }
                return false;
            });

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES, nil);
        });
    });
}

@end
