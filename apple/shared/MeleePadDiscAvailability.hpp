#pragma once

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <string>

namespace MeleePadDiscAvailability {
inline bool IsFile(const std::filesystem::path& path) {
    if (path.empty()) return false;
    std::error_code error;
    return std::filesystem::is_regular_file(path, error) && !error;
}

// Use the same image order for Home readiness and the runtime boot. A device
// never follows an old absolute path into another app container; Simulator
// development may use its configured external image path.
inline std::filesystem::path Find(const std::filesystem::path& gameDataDirectory,
                                  const std::filesystem::path& retained,
                                  const std::filesystem::path& bundled,
                                  bool allowExternalRetained) {
    if (!retained.empty()) {
        const auto rebased = gameDataDirectory / retained.filename();
        if (IsFile(rebased)) return rebased;
    }
    std::error_code error;
    for (std::filesystem::directory_iterator it(gameDataDirectory, error), end;
         !error && it != end; it.increment(error)) {
        auto extension = it->path().extension().string();
        std::transform(extension.begin(), extension.end(), extension.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        if ((extension == ".iso" || extension == ".gcm" || extension == ".ciso" ||
             extension == ".rvz") && IsFile(it->path()))
            return it->path();
    }
    if (allowExternalRetained && IsFile(retained)) return retained;
    if (IsFile(bundled)) return bundled;
    return {};
}
}  // namespace MeleePadDiscAvailability
