# CMake toolchain for building ModernGekko's Dolphin-derived core for the
# iOS Simulator (arm64). Product path has no JIT: the game CPU runs as a
# statically recompiled module through the compatibility runtime, with
# interpreter fallback and the portable software vertex loader selected by the
# shared iOS runtime patch.
set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_VERSION 16.0)
set(CMAKE_SYSTEM_PROCESSOR arm64)
set(CMAKE_OSX_SYSROOT iphonesimulator CACHE STRING "")
set(CMAKE_OSX_ARCHITECTURES arm64 CACHE STRING "")
set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH YES)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "")
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES CMAKE_OSX_SYSROOT CMAKE_OSX_ARCHITECTURES)

set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_OBJCXX_COMPILER_WORKS TRUE)
