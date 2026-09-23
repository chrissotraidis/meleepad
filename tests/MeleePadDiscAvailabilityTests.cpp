#include "MeleePadDiscAvailability.hpp"
#include <cassert>
#include <fstream>

int main(int argc, char** argv) {
    assert(argc == 2);
    namespace fs = std::filesystem;
    const fs::path root(argv[1]);
    const auto gameData = root / "GameData-r2";
    const auto oldContainer = root / "old-container/GALE01.iso";
    const auto bundled = root / "Bundle/GALE01.iso";
    fs::create_directories(gameData);
    fs::create_directories(oldContainer.parent_path());
    fs::create_directories(bundled.parent_path());
    using MeleePadDiscAvailability::Find;
    assert(Find(gameData, oldContainer, bundled, false).empty());

    // An app update changes the container path, but the imported image survives.
    std::ofstream(gameData / "GALE01.iso") << "image";
    assert(Find(gameData, oldContainer, bundled, false) == gameData / "GALE01.iso");
    fs::remove(gameData / "GALE01.iso");

    // Another supported image wins over an obsolete external path or bundle.
    std::ofstream(oldContainer) << "old";
    std::ofstream(bundled) << "bundle";
    std::ofstream(gameData / "Melee.CISO") << "current";
    assert(Find(gameData, oldContainer, bundled, true) == gameData / "Melee.CISO");
    fs::remove(gameData / "Melee.CISO");

    // Simulator development can use its external image; a device cannot.
    assert(Find(gameData, oldContainer, {}, true) == oldContainer);
    assert(Find(gameData, oldContainer, bundled, false) == bundled);
    fs::remove(bundled);
    assert(Find(gameData, oldContainer, bundled, false).empty());

    // A directory or unrelated extension never makes the setup look ready.
    fs::create_directory(gameData / "fake.iso");
    std::ofstream(gameData / "notes.txt") << "not an image";
    assert(Find(gameData, {}, {}, false).empty());
}
