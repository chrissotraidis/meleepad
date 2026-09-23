#include "slippi-replay-library.hpp"
#include <cassert>
#include <fstream>

int main(int argc, char** argv) {
  assert(argc == 2);
  namespace fs = std::filesystem;
  const fs::path root(argv[1]);
  const auto run = root / "SlippiDirectRuns/12345678-1234-1234-1234-123456789abc/User/Slippi/Replays";
  const auto other = root / "SlippiDirectRuns/not-a-run/User/Slippi/Replays";
  fs::create_directories(run / "2026-09-Mainline");
  fs::create_directories(other);
  std::ofstream(run / "Game_first.slp") << "first";
  std::ofstream(run / "2026-09-Mainline/Game_second.slp") << "second";
  std::ofstream(run / "Empty.slp");
  std::ofstream(other / "Game_ignored.slp") << "ignored";
  fs::create_symlink(run / "Game_first.slp", run / "Link.slp");
  fs::create_directory_symlink(other, run / "linked-month");
  const auto linkedRun = root / "SlippiDirectRuns/abcdefab-1234-1234-1234-123456789abc";
  fs::create_directories(linkedRun);
  fs::create_directory_symlink(run.parent_path().parent_path(), linkedRun / "User");
  const auto earlier = fs::file_time_type::clock::now() - std::chrono::hours(2);
  fs::last_write_time(run / "Game_first.slp", earlier);
  auto found = SlippiReplayLibrary::Recent(root);
  assert(found.size() == 2);
  assert(found[0].path.filename() == "Game_second.slp");
  assert(found[1].path.filename() == "Game_first.slp");
  assert(SlippiReplayLibrary::IsStillShareable(found[0]));
  assert(SlippiReplayLibrary::Recent(root, 1).size() == 1);
  std::ofstream(run / "2026-09-Mainline/Game_second.slp", std::ios::app) << "changed";
  assert(!SlippiReplayLibrary::IsStillShareable(found[0]));
  fs::remove(run / "Game_first.slp");
  assert(!SlippiReplayLibrary::IsStillShareable(found[1]));
  assert(SlippiReplayLibrary::Recent(root / "missing").empty());
}
