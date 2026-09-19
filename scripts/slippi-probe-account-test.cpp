#include "slippi-probe-account.hpp"
#include <fstream>
#include <iostream>

int main(int argc, char** argv) {
  if (argc != 2) return 2;
  const std::filesystem::path root = argv[1];
  if (!std::filesystem::create_directory(root)) return 2;
  int checks = 0, failures = 0;
  auto check = [&](bool ok) { ++checks; failures += !ok; };
  const std::string valid = R"({"uid":"synthetic-a","playKey":"synthetic-key-a","displayName":"Test A","connectCode":"TEST#1","latestVersion":"3.6.4","extra":"discard"})";
  std::string normalized;
  check(SlippiProbeAccount::Normalize(valid, normalized));
  check(normalized.find("discard") == std::string::npos);
  for (const auto& bad : {std::string("[]"), std::string("{}"), std::string("not json"), std::string(16385, 'x')})
    check(!SlippiProbeAccount::Normalize(bad, normalized));
  auto invalid = nlohmann::json::parse(valid);
  invalid["playKey"] = ""; check(!SlippiProbeAccount::Normalize(invalid.dump(), normalized));
  invalid["playKey"] = 12; check(!SlippiProbeAccount::Normalize(invalid.dump(), normalized));
  invalid["playKey"] = std::string("key\0suffix", 10); check(!SlippiProbeAccount::Normalize(invalid.dump(), normalized));
  const auto source = root / "source.json";
  { std::ofstream file(source); file << valid; }
  std::filesystem::create_symlink(source.filename(), root / "alias.json");
  const auto user = root / "runtime";
  {
    SlippiProbeAccount::RuntimeCopy copy;
    check(!copy.Install(root / "alias.json", user));
    check(copy.Install(source, user));
    struct stat info{}; check(::stat((user / "Slippi/user.json").c_str(), &info) == 0 && (info.st_mode & 0777) == 0600);
    check(!copy.Install(source, user));
    SlippiProbeAccount::RuntimeCopy second;
    check(!second.Install(source, user));
    check(std::filesystem::exists(user / "Slippi/user.json"));
  }
  check(!std::filesystem::exists(user / "Slippi/user.json"));
  check(std::filesystem::exists(source));
  {
    SlippiProbeAccount::RuntimeCopy copy;
    check(!copy.InstallSerialized("{}", user));
    check(copy.InstallSerialized(valid, user));
    check(!copy.InstallSerialized(valid, root / "other-runtime"));
  }
  check(!std::filesystem::exists(user / "Slippi/user.json"));
  std::cout << "{\"checks\":" << checks << ",\"failures\":" << failures
            << ",\"synthetic_only\":true,\"network_attempted\":false}\n";
  return failures ? 1 : 0;
}
