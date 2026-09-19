// Execute under sandbox-exec with network access denied and a fresh test directory.
// Tests FFI ownership/lifecycle only, not authentication, ISO validity or gameplay.
#include "SlippiRustExtensions.h"
#include <cstdio>
#include <filesystem>

static void OSD(const char*, uint32_t, uint32_t) {}

int main(int argc, char** argv)
{
  namespace fs = std::filesystem;
  if (argc != 2 || fs::exists(argv[1])) return 2;
  const fs::path root = fs::absolute(argv[1]);
  int completed = 0;
  for (int cycle = 0; cycle < 3; ++cycle)
  {
    const auto directory = root / std::to_string(cycle);
    fs::create_directories(directory);
    const auto user_path = directory.string();
    const auto iso_path = (directory / "nonexistent-test-image.iso").string();
    SlippiRustEXIConfig config{iso_path.c_str(), user_path.c_str(), "0.0.0-meleepad-probe", OSD};
    const auto device = slprs_exi_device_create(config);
    if (!device) return 3;
    bool pass = !slprs_user_get_is_logged_in(device);
    auto* user = slprs_user_get_info(device);
    pass = pass && user && user->uid && user->uid[0] == '\0';
    if (user) slprs_user_free_info(user);
    slprs_exi_device_destroy(device);
    if (!pass) return 4;
    ++completed;
  }
  std::printf("{\"lifecycle_cycles\":%d,\"anonymous_state_pass\":true,\"game_executed\":false}\n", completed);
  return 0;
}
