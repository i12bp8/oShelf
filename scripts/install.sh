#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
plugin_id=io.github.i12bp8.oshelf
plugin_root=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins
destination=$plugin_root/$plugin_id
command -v python3 >/dev/null
omarchy plugin validate "$source_dir"
make -C "$source_dir"
mkdir -p -- "$plugin_root"
if ! mkdir -- "$destination"; then
  echo "An installation already exists at $destination. Use Omarchy to remove or update it." >&2
  exit 1
fi
cp -- "$source_dir/Service.qml" "$source_dir/LICENSE" "$source_dir/README.md" "$destination/"
cp -R -- "$source_dir/components" "$source_dir/lib" "$destination/"
mkdir -- "$destination/native"
cp -- "$source_dir/native/qmldir" "$source_dir/native/plugins.qmltypes" "$source_dir/native/liboshelf-native.so" "$destination/native/"
mkdir -- "$destination/scripts"
cp -- "$source_dir/scripts/metadata.py" "$destination/scripts/"
cp -- "$source_dir/manifest.json" "$destination/"
omarchy-shell shell rescanPlugins
for attempt in {1..20}; do
  if omarchy-shell shell listPlugins | python3 -c 'import json, sys; sys.exit(not any(p["id"] == "io.github.i12bp8.oshelf" for p in json.load(sys.stdin)))'; then
    exec omarchy plugin enable "$plugin_id"
  fi
  sleep 0.25
done
echo "Installed, but Omarchy has not finished discovering oShelf. Run: omarchy plugin enable $plugin_id" >&2
exit 1
