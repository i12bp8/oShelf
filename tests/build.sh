#!/usr/bin/env bash
set -euo pipefail
if (( $# < 1 || $# > 2 )); then
  echo "Usage: $0 /path/to/wlr-virtual-pointer-unstable-v1.xml [output-directory]" >&2
  exit 2
fi
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
output=${2:-$source_dir/../build/tests}
mkdir -p -- "$output"
wayland-scanner client-header "$1" "$output/pointer.h"
wayland-scanner private-code "$1" "$output/pointer-protocol.c"
# pkg-config intentionally expands compiler/linker flags, never user payloads.
cc "$source_dir/pointer.c" "$output/pointer-protocol.c" -I "$output" -o "$output/pointer" $(pkg-config --cflags --libs wayland-client)
c++ -fPIC "$source_dir/transfer.cpp" -o "$output/transfer" $(pkg-config --cflags --libs Qt6Widgets)
