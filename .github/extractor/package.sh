#!/bin/bash
# Packages ZAPD and the 8.0.6 extraction scripts into a self-contained folder.
# Usage: package.sh <shipwright-8.0.6-source> <cmake-build-dir> <output-dir>
set -euo pipefail

src="$1"
build="$2"
out="$3"
self="$(cd "$(dirname "$0")" && pwd)"

rm -rf "$out"
mkdir -p "$out/ZAPD/lib" "$out/OTRExporter" "$out/soh/assets"

zapd="$(find "$build" -name ZAPD.out -type f | head -n 1)"
[ -n "$zapd" ] || { echo "ZAPD.out not found in $build" >&2; exit 1; }
cp "$zapd" "$out/ZAPD/ZAPD.out"

cp "$src"/OTRExporter/extract_assets.py "$src"/OTRExporter/rom_info.py \
   "$src"/OTRExporter/rom_chooser.py "$out/OTRExporter/"
cp -R "$src/OTRExporter/CFG" "$out/OTRExporter/"
cp -R "$src/soh/assets/xml" "$src/soh/assets/custom" "$out/soh/assets/"
cp "$self/extract.sh" "$self/README.txt" "$out/"
chmod +x "$out/extract.sh"

# Copy every MacPorts library ZAPD loads next to it and point the binaries at the copies.
fix_deps() {
    local bin="$1" dep name
    for dep in $(otool -L "$bin" | awk 'NR > 1 && $1 ~ /^\/opt\/local\// { print $1 }'); do
        name="$(basename "$dep")"
        if [ ! -f "$out/ZAPD/lib/$name" ]; then
            cp "$dep" "$out/ZAPD/lib/$name"
            chmod u+w "$out/ZAPD/lib/$name"
            install_name_tool -id "@executable_path/lib/$name" "$out/ZAPD/lib/$name"
            fix_deps "$out/ZAPD/lib/$name"
        fi
        install_name_tool -change "$dep" "@executable_path/lib/$name" "$bin"
    done
}
fix_deps "$out/ZAPD/ZAPD.out"

for f in "$out/ZAPD/ZAPD.out" "$out"/ZAPD/lib/*; do
    [ -f "$f" ] && codesign --force --sign - "$f"
done

if otool -L "$out/ZAPD/ZAPD.out" "$out"/ZAPD/lib/* 2>/dev/null | grep -q '/opt/local/'; then
    echo "A bundled binary still references /opt/local:" >&2
    otool -L "$out/ZAPD/ZAPD.out" "$out"/ZAPD/lib/* | grep '/opt/local/' >&2
    exit 1
fi
otool -L "$out/ZAPD/ZAPD.out"
