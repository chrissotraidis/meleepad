#pragma once
// Private interoperability probe credential handoff. Never bundle an account.
// This validates a local file only; Slippi's service still authenticates the key.
#include <nlohmann/json.hpp>
#include <array>
#include <cerrno>
#include <filesystem>
#include <fcntl.h>
#include <string>
#include <sys/stat.h>
#include <unistd.h>

namespace SlippiProbeAccount {
inline bool Normalize(const std::string& input, std::string& output) {
  output.clear();
  if (input.empty() || input.size() > 16384) return false;
  auto value = nlohmann::json::parse(input, nullptr, false);
  if (!value.is_object()) return false;
  nlohmann::json clean = nlohmann::json::object();
  const std::array<std::pair<const char*, size_t>, 5> fields = {{
      {"uid", 128}, {"playKey", 2048}, {"displayName", 256},
      {"connectCode", 64}, {"latestVersion", 128}}};
  for (const auto& [key, limit] : fields) {
    if (value.find(key) == value.end() || !value[key].is_string()) return false;
    const auto& text = value[key].get_ref<const std::string&>();
    if (text.empty() || text.size() > limit) return false;
    for (unsigned char c : text) if (c < 32 || c == 127) return false;
    clean[key] = text;
  }
  // Chat and unrelated export fields are not needed for a Direct acceptance test.
  output = clean.dump();
  return true;
}

class RuntimeCopy {
  std::filesystem::path path;
public:
  RuntimeCopy() = default;
  RuntimeCopy(const RuntimeCopy&) = delete;
  RuntimeCopy& operator=(const RuntimeCopy&) = delete;
  ~RuntimeCopy() { if (!path.empty()) ::unlink(path.c_str()); }
  bool Install(const std::filesystem::path& source, const std::filesystem::path& user) {
    if (!path.empty()) return false;
    const int fd = ::open(source.c_str(), O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) return false;
    struct stat info{};
    if (::fstat(fd, &info) || !S_ISREG(info.st_mode) || info.st_size <= 0 || info.st_size > 16384) {
      ::close(fd); return false;
    }
    std::string input(static_cast<size_t>(info.st_size), '\0');
    size_t offset = 0;
    while (offset < input.size()) {
      const auto count = ::read(fd, input.data() + offset, input.size() - offset);
      if (count < 0 && errno == EINTR) continue;
      if (count <= 0) { ::close(fd); return false; }
      offset += static_cast<size_t>(count);
    }
    char extra;
    ssize_t trailing;
    do { trailing = ::read(fd, &extra, 1); } while (trailing < 0 && errno == EINTR);
    ::close(fd);
    if (trailing != 0) return false;
    return InstallSerialized(input, user);
  }
  // Allows a platform Keychain adapter to hand off an account without first
  // writing an additional plaintext source file.
  bool InstallSerialized(const std::string& input, const std::filesystem::path& user) {
    if (!path.empty()) return false;
    std::string account;
    if (!Normalize(input, account)) return false;
    const auto directory = user / "Slippi";
    std::error_code error;
    std::filesystem::create_directories(directory, error);
    if (error || std::filesystem::is_symlink(directory)) return false;
    const auto destination = directory / "user.json";
    const int output = ::open(destination.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
    if (output < 0) return false;
    path = destination;
    size_t offset = 0;
    while (offset < account.size()) {
      const auto count = ::write(output, account.data() + offset, account.size() - offset);
      if (count < 0 && errno == EINTR) continue;
      if (count <= 0) { ::close(output); ::unlink(path.c_str()); path.clear(); return false; }
      offset += static_cast<size_t>(count);
    }
    if (::close(output)) { ::unlink(path.c_str()); path.clear(); return false; }
    return true;
  }
};
}
