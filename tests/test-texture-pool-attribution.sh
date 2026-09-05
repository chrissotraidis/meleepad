#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TIMING="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Common/FramePhaseTiming.h"
PRESENT="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/VideoCommon/Present.cpp"
TEXTURE_CACHE="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/VideoCommon/TextureCacheBase.cpp"
TEXTURE_CACHE_HEADER="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/VideoCommon/TextureCacheBase.h"
PATCH="$ROOT/patches/moderngekko-dolphin/0046-texture-pool-attribution.patch"
BUILD_DIR="$(mktemp -d /tmp/meleepad-texture-pool-attribution.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

for contract in \
  s_texture_pool_hits \
  s_texture_pool_empty_misses \
  s_texture_pool_same_frame_misses \
  s_texture_pool_expirations \
  s_texture_pool_recent_expiry_misses \
  s_texture_create_calls \
  s_texture_create_ns \
  s_framebuffer_create_calls \
  s_framebuffer_create_ns; do
  grep -Fq -- "$contract" "$TIMING"
  grep -Fq -- "$contract" "$PATCH"
done

grep -Fq 'Common::FramePhaseTiming::AddTexturePoolLookup' "$TEXTURE_CACHE"
grep -Fq 'Common::FramePhaseTiming::AddTexturePoolExpirations' "$TEXTURE_CACHE"
grep -Fq 'Common::FramePhaseTiming::AddTexturePoolRecentExpiryMiss' "$TEXTURE_CACHE"
grep -Fq 'Common::FramePhaseTiming::AddTextureCreate' "$TEXTURE_CACHE"
grep -Fq 'Common::FramePhaseTiming::AddFramebufferCreate' "$TEXTURE_CACHE"
grep -Fq 'm_recently_expired_texture_configs' "$TEXTURE_CACHE_HEADER"
grep -Fq 'std::filesystem::path(File::GetUserPath(D_LOGS_IDX))' "$PRESENT"
grep -Fq 'texture_pool_hits,texture_pool_empty_misses,texture_pool_same_frame_misses,texture_pool_expirations,texture_pool_recent_expiry_misses,texture_create_calls,texture_create_ms,framebuffer_create_calls,framebuffer_create_ms' "$PRESENT"
grep -Fq 'texture_pool_attribution_patch=' "$ROOT/scripts/bootstrap-dependencies.sh"

"${CXX:-c++}" -std=c++20 -O2 \
  -I"$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core" \
  "$ROOT/scripts/texture_pool_attribution_preflight.cpp" \
  -o "$BUILD_DIR/texture_pool_attribution_preflight"
"$BUILD_DIR/texture_pool_attribution_preflight"

echo "Texture-pool attribution source checks passed"
