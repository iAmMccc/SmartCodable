#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  raw) source_file=RawInput.swift; max_len=512 ;;
  structured) source_file=StructuredSemantic.swift; max_len=64 ;;
  *) printf 'Usage: %s <raw|structured> [runs]\n' "$0" >&2; exit 2 ;;
esac

target="$1"
runs="${2:-32}"
if [[ ! "$runs" =~ ^[1-9][0-9]*$ ]]; then
  printf 'runs must be a positive integer\n' >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="${SMART_FUZZ_SCRATCH:-${TMPDIR:-/tmp}/smartcodable-fuzzing-$(id -u)}"
llvm_prefix="$(HOMEBREW_NO_AUTO_UPDATE=1 brew --prefix llvm)"
swift_binary="$(xcrun --find swiftc)"
swift_lib_dir="$(dirname "$(dirname "$swift_binary")")/lib/swift/macosx"
output="$scratch/bin/$target"
corpus="$scratch/corpus/$target"
artifacts="$scratch/artifacts/$target"

mkdir -p "$scratch/bin" "$corpus" "$artifacts"
cp "$repo_root/Fuzzing/Corpus/Seeds/$target/"* "$corpus/"

# Apple's Swift driver rejects -sanitize=fuzzer on macOS. Use its supported
# sanitizer coverage counters with the Homebrew clang libFuzzer driver.
# Binary layout follows the active SwiftPM scratch path; do not hardcode a triple.
build_args=(
  --package-path "$repo_root"
  --scratch-path "$scratch/package"
  -Xswiftc -sanitize=undefined
  -Xswiftc -sanitize-coverage=edge,inline-8bit-counters,pc-table
)
swift build "${build_args[@]}"
products="$(swift build "${build_args[@]}" --show-bin-path | tail -n 1)"

if [[ -e "$products/Modules/SmartCodable.swiftmodule" ]]; then
  module_dir="$products/Modules"
elif [[ -e "$products/SmartCodable.swiftmodule" ]]; then
  module_dir="$products"
else
  printf 'SmartCodable.swiftmodule not found in %s\n' "$products" >&2
  exit 1
fi

link_inputs=()
if [[ -f "$products/libSmartCodable.a" ]]; then
  link_inputs+=("$products/libSmartCodable.a")
else
  for object in "$products/SmartCodable.build/"*.o; do
    [[ -e "$object" ]] || continue
    link_inputs+=("$object")
  done
fi
if [[ ${#link_inputs[@]} -eq 0 ]]; then
  printf 'SmartCodable library or object files not found in %s\n' "$products" >&2
  exit 1
fi

"$swift_binary" -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -parse-as-library -emit-object \
  -sanitize=undefined -sanitize-coverage=edge,inline-8bit-counters,pc-table \
  -I "$module_dir" "$repo_root/Fuzzing/Sources/$source_file" \
  -o "$scratch/bin/$target.o"

"$llvm_prefix/bin/clang++" -isysroot "$(xcrun --sdk macosx --show-sdk-path)" \
  -fsanitize=fuzzer "$scratch/bin/$target.o" "${link_inputs[@]}" \
  -L "$swift_lib_dir" -lswiftCore -lswiftFoundation \
  -framework Foundation -framework AppKit -framework CoreGraphics \
  -o "$output"

"$output" -runs="$runs" -max_len="$max_len" -timeout=2 \
  -artifact_prefix="$artifacts/" "$corpus"
