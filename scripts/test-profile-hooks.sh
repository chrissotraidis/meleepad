#!/usr/bin/env bash
# Prove that an instrumented module drops pre-reset counts and dumps post-reset counts.
set -euo pipefail

module=${1:-}
release_module=${2:-}
if [[ -z "$module" || ! -f "$module" ]]; then
  echo "usage: $0 /path/to/instrumented-module.dylib [release-module.dylib]" >&2
  exit 2
fi

required_symbols=$(nm -gU "$module" | awk '/staticrecomp_(get_module|profile_reset|profile_dump)$/ {print $3}')
for symbol in _staticrecomp_get_module _staticrecomp_profile_reset _staticrecomp_profile_dump; do
  if ! grep -Fqx "$symbol" <<<"$required_symbols"; then
    echo "missing instrumented export: $symbol" >&2
    exit 1
  fi
done

if [[ -n "$release_module" ]]; then
  if [[ ! -f "$release_module" ]]; then
    echo "release module not found: $release_module" >&2
    exit 2
  fi
  if nm -gU "$release_module" | grep -Eq 'staticrecomp_profile_(reset|dump)$'; then
    echo "release module unexpectedly exports instrumentation hooks" >&2
    exit 1
  fi
fi

profile_dir=$(mktemp -d /private/tmp/ssbmpad-profile-hooks.XXXXXX)
trap 'rm -rf "$profile_dir"' EXIT

env LLVM_PROFILE_FILE="$profile_dir/hook-%p.profraw" swift -e '
import Darwin
guard CommandLine.arguments.count == 2 else { fatalError("module path required") }
guard let handle = dlopen(CommandLine.arguments[1], RTLD_NOW | RTLD_LOCAL) else {
  fatalError(String(cString: dlerror()))
}
typealias GetModule = @convention(c) () -> UnsafeRawPointer?
typealias Reset = @convention(c) () -> Void
typealias Dump = @convention(c) () -> Int32
let getModule = unsafeBitCast(dlsym(handle, "staticrecomp_get_module"), to: GetModule.self)
let reset = unsafeBitCast(dlsym(handle, "staticrecomp_profile_reset"), to: Reset.self)
let dump = unsafeBitCast(dlsym(handle, "staticrecomp_profile_dump"), to: Dump.self)
for _ in 0..<7 { _ = getModule() }
reset()
for _ in 0..<3 { _ = getModule() }
guard dump() == 0 else { fatalError("profile dump failed") }
dlclose(handle)
' "$module"

profile=$(find "$profile_dir" -name 'hook-*.profraw' -type f -print)
if [[ -z "$profile" || $(wc -l <<<"$profile") -ne 1 ]]; then
  echo "expected exactly one raw profile" >&2
  exit 1
fi
xcrun llvm-profdata merge -o "$profile_dir/hook.profdata" "$profile"
counts=$(xcrun llvm-profdata show --all-functions --counts "$profile_dir/hook.profdata")
awk '
  /^  staticrecomp_get_module:/ {target="get"; next}
  /^  staticrecomp_profile_reset:/ {target="reset"; next}
  /^  staticrecomp_profile_dump:/ {target="dump"; next}
  target != "" && /Function count:/ {
    count[target]=$3
    target=""
  }
  END {
    if (count["get"] != 3 || count["reset"] != 0 || count["dump"] != 1)
      exit 1
  }
' <<<"$counts"

echo "profile hooks passed: pre-reset=7 excluded, post-reset=3 retained, dump=1"
