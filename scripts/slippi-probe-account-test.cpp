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
  const auto runs = root / "SlippiDirectRuns";
  const auto run = runs / "12345678-1234-1234-1234-123456789abc";
  const auto staged = run / "User/Slippi";
  std::filesystem::create_directories(staged);
  { std::ofstream file(staged / "user.json"); file << valid; }
  { std::ofstream file(run / "incidents.csv"); file << "diagnostic\n"; }
  const auto unrelated = runs / "not-a-run/User/Slippi";
  std::filesystem::create_directories(unrelated);
  { std::ofstream file(unrelated / "user.json"); file << valid; }
  const auto outside = root / "outside";
  std::filesystem::create_directories(outside / "User/Slippi");
  { std::ofstream file(outside / "User/Slippi/user.json"); file << valid; }
  std::filesystem::create_directory_symlink(outside, runs / "abcdefab-1234-1234-1234-123456789abc");
  const auto nested_link_run = runs / "abcdefac-1234-1234-1234-123456789abc";
  std::filesystem::create_directory(nested_link_run);
  std::filesystem::create_directory_symlink(outside / "User", nested_link_run / "User");
  check(SlippiProbeAccount::RemoveAbandonedRuntimeCopies(runs) == 1);
  check(!std::filesystem::exists(staged / "user.json"));
  check(std::filesystem::exists(run / "incidents.csv"));
  check(std::filesystem::exists(unrelated / "user.json"));
  check(std::filesystem::exists(outside / "User/Slippi/user.json"));
  check(SlippiProbeAccount::RemoveAbandonedRuntimeCopies(runs) == 0);
  std::cout << "{\"checks\":" << checks << ",\"failures\":" << failures
            << ",\"synthetic_only\":true,\"network_attempted\":false}\n";
  return failures ? 1 : 0;
}
