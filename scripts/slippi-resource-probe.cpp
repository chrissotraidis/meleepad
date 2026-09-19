// Exercises the adapted Slippi resource loader with a synthetic disc and resources.
// No retail game content or game execution is involved.
#include "Core/Slippi/SlippiGameFileLoader.h"
#include "Core/Core.h"
#include "Core/HW/DVD/DVDThread.h"
#include "Core/System.h"
#include "Common/Config/Config.h"
#include "Common/FileUtil.h"
#include "DiscIO/DirectoryBlob.h"
#include "DiscIO/Volume.h"
#include <open-vcdiff/src/google/vcencoder.h>
#include <array>
#include <filesystem>
#include <fstream>
#include <cstdio>

namespace fs = std::filesystem;
void Write(const fs::path& path, const std::string& data)
{
  fs::create_directories(path.parent_path());
  std::ofstream(path, std::ios::binary).write(data.data(), data.size());
}

int main(int argc, char** argv)
{
  if (argc != 2 || fs::exists(argv[1])) return 2;
  const fs::path root = fs::absolute(argv[1]);
  const fs::path resource_dir = root / "resources/GameFiles/GALE01";
  const std::string original = "synthetic resource dictionary for Slippi loader testing";
  const std::string changed = "synthetic resource dictionary MODIFIED and expanded by VCDIFF";
  std::string diff;
  open_vcdiff::VCDiffEncoder encoder(original.data(), original.size());
  if (!encoder.Encode(changed.data(), changed.size(), &diff)) return 3;
  Write(resource_dir / "patched.dat.diff", diff);
  Write(resource_dir / "bad.dat.diff", "invalid delta");
  Write(resource_dir / "absent.dat.diff", diff);
  Write(resource_dir / "standalone.dat", "standalone resource");

  // Minimal generated disc metadata for Dolphin's real directory-backed volume.
  std::string boot(0x440, '\0');
  boot.replace(0, 6, "TEST01");
  boot[0x1c] = 0xc2; boot[0x1d] = 0x33; boot[0x1e] = 0x9f; boot[0x1f] = 0x3d;
  Write(root / "disc/sys/boot.bin", boot);
  Write(root / "disc/sys/bi2.bin", std::string(0x2000, '\0'));
  Write(root / "disc/sys/apploader.img", std::string(0x20, '\0'));
  std::string dol(0x104, '\0');
  dol[2] = 1; dol[0x48] = 0x80; dol[0x4a] = 0x31; dol[0x93] = 4;
  dol[0xe0] = 0x80; dol[0xe2] = 0x31; dol[0x100] = 0x48;
  Write(root / "disc/sys/main.dol", dol);
  for (const char* name : {"patched.dat", "bad.dat", "GrPs1.dat"})
    Write(root / "disc/files" / name, original);

  Config::Init();
  Core::DeclareAsCPUThread();
  auto& system = Core::System::GetInstance();
  auto& dvd = system.GetDVDThread();
  SlippiGameFileLoader loader((root / "resources").string());
  std::string data;
  int checks = 0, failures = 0;
  auto check = [&](bool value) { ++checks; if (!value) { ++failures; std::fprintf(stderr, "failed check %d\n", checks); } };
  check(loader.LoadFile(system, "standalone.dat", data) == 19 && data == "standalone resource");
  Write(resource_dir / "standalone.dat", "changed on disk");
  check(loader.LoadFile(system, "standalone.dat", data) == 19 && data == "standalone resource");
  check(loader.LoadFile(system, "missing.dat", data) == 0 && data.empty());
  check(loader.LoadFile(system, "patched.dat", data) == 0 && data.empty()); // no disc

  auto blob = DiscIO::DirectoryBlobReader::Create((root / "disc/sys/main.dol").string());
  check(blob != nullptr);
  if (!blob) return 4;
  dvd.SetDisc(DiscIO::CreateVolume(std::move(blob)));
  check(dvd.HasDisc());
  check(loader.LoadFile(system, "patched.dat", data) == changed.size() && data == changed);
  check(loader.LoadFile(system, "GrPs1.dat", data) == original.size() && data == original);
  check(loader.LoadFile(system, "bad.dat", data) == 0 && data.empty());
  check(loader.LoadFile(system, "absent.dat", data) == 0 && data.empty());
  std::vector<u8> bytes{1, 2, 3};
  check(!dvd.ReadFile("no-such-disc-file.dat", bytes) && bytes.empty());
  dvd.SetDisc(nullptr);
  Core::UndeclareAsCPUThread();
  Config::Shutdown();
  std::printf("{\"checks\":%d,\"failures\":%d,\"game_executed\":false}\n", checks, failures);
  return failures ? 5 : 0;
}
