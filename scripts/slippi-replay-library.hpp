#pragma once

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <string>
#include <vector>

namespace SlippiReplayLibrary {
struct Replay {
  std::filesystem::path path;
  std::filesystem::file_time_type modified;
  uintmax_t bytes;
};

inline bool IsRunId(const std::string& name) {
  if (name.size() != 36) return false;
  for (size_t i = 0; i < name.size(); ++i) {
    if (i == 8 || i == 13 || i == 18 || i == 23) {
      if (name[i] != '-') return false;
    } else if (!std::isxdigit(static_cast<unsigned char>(name[i]))) {
      return false;
    }
  }
  return true;
}

inline bool IsRealDirectory(const std::filesystem::path& path) {
  std::error_code error;
  const auto status = std::filesystem::symlink_status(path, error);
  return !error && std::filesystem::is_directory(status);
}

inline void AddFiles(const std::filesystem::path& directory, std::vector<Replay>& found,
                     bool includeMonthlyFolders = false) {
  if (!IsRealDirectory(directory)) return;
  std::error_code error;
  for (std::filesystem::directory_iterator it(directory, error), end;
       !error && it != end; it.increment(error)) {
    const auto path = it->path();
    std::error_code fileError;
    const auto status = std::filesystem::symlink_status(path, fileError);
    if (fileError) continue;
    if (includeMonthlyFolders && std::filesystem::is_directory(status)) {
      AddFiles(path, found);
    } else if (std::filesystem::is_regular_file(status) && path.extension() == ".slp") {
      const auto bytes = std::filesystem::file_size(path, fileError);
      if (fileError) continue;
      // Empty files are not useful. Large files are still listed; sharing never reads them here.
      if (bytes == 0) continue;
      const auto modified = std::filesystem::last_write_time(path, fileError);
      if (fileError) continue;
      found.push_back({path, modified, bytes});
    }
  }
}

inline std::vector<Replay> Recent(const std::filesystem::path& userDirectory,
                                  size_t limit = 8) {
  std::vector<Replay> found;
  const auto runs = userDirectory / "SlippiDirectRuns";
  if (!IsRealDirectory(runs) || limit == 0) return found;
  std::error_code error;
  for (std::filesystem::directory_iterator it(runs, error), end;
       !error && it != end; it.increment(error)) {
    const auto run = it->path();
    if (!IsRunId(run.filename().string()) || !IsRealDirectory(run)) continue;
    if (!IsRealDirectory(run / "User") || !IsRealDirectory(run / "User/Slippi"))
      continue;
    AddFiles(run / "User/Slippi/Replays", found, true);
  }
  std::sort(found.begin(), found.end(), [](const Replay& a, const Replay& b) {
    return a.modified == b.modified ? a.path.string() > b.path.string()
                                    : a.modified > b.modified;
  });
  if (found.size() > limit) found.resize(limit);
  return found;
}

inline bool IsStillShareable(const Replay& replay) {
  std::error_code error;
  const auto status = std::filesystem::symlink_status(replay.path, error);
  if (error || !std::filesystem::is_regular_file(status)) return false;
  const auto bytes = std::filesystem::file_size(replay.path, error);
  return !error && bytes > 0 && bytes == replay.bytes &&
         std::filesystem::last_write_time(replay.path, error) == replay.modified && !error;
}
}  // namespace SlippiReplayLibrary
