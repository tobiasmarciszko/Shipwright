#!/bin/bash
# Creates oot.otr (or oot-mq.otr) and soh.otr for Ship of Harkinian 8.0.6
# from an Ocarina of Time ROM.
#
# Usage: bash extract.sh /path/to/rom.z64
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    echo "Usage: bash extract.sh /path/to/rom.z64" >&2
    exit 64
fi
rom_in="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 6) else 1)' 2>/dev/null; then
    echo "Python 3 is missing. Install Apple's Command Line Tools with:" >&2
    echo "    xcode-select --install" >&2
    echo "then run this script again." >&2
    exit 1
fi

# Files downloaded with a browser are quarantined, which stops ZAPD from running.
xattr -dr com.apple.quarantine "$here" 2>/dev/null || true
chmod +x "$here/ZAPD/ZAPD.out"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Convert .n64/.v64 byte orders to .z64 and check the ROM is one 8.0.6 supports.
python3 - "$rom_in" "$work/rom.z64" "$here/OTRExporter" <<'EOF'
import sys
src, dst, exporter = sys.argv[1:4]
data = bytearray(open(src, "rb").read())
magic = bytes(data[:4])
if magic == b"\x37\x80\x40\x12":      # .v64: 16-bit byte swapped
    data[0::2], data[1::2] = data[1::2], data[0::2]
elif magic == b"\x40\x12\x37\x80":    # .n64: 32-bit little endian
    for i in range(0, len(data) - 3, 4):
        data[i:i + 4] = data[i:i + 4][::-1]
elif magic != b"\x80\x37\x12\x40":
    sys.exit("This file is not an N64/GameCube Ocarina of Time ROM.")
open(dst, "wb").write(data)

sys.path.insert(0, exporter)
import os
os.chdir(exporter)
from rom_info import Checksums, ROM_INFO_TABLE
checksum = bytes(data[16:20]).hex().upper()
version = Checksums(checksum) if Checksums.has_value(checksum) else None
if len(data) <= 20 * 1024 * 1024 or version not in ROM_INFO_TABLE:
    supported = ", ".join(c.name for c in ROM_INFO_TABLE)
    sys.exit("This ROM version (%s, checksum %s) is not supported by 8.0.6.\n"
             "Supported versions: %s" % (version.name if version else "unknown", checksum, supported))
print("ROM version: %s" % version.name)
EOF

out="$here/output"
mkdir -p "$out"
cd "$here/OTRExporter"
rm -f oot.otr oot-mq.otr soh.otr
python3 extract_assets.py -z ../ZAPD/ZAPD.out "$work/rom.z64" --non-interactive \
    --xml-root ../soh/assets/xml \
    --custom-otr-file soh.otr --custom-assets-path ../soh/assets/custom \
    --port-ver 8.0.6

rm -f "$out/oot.otr" "$out/oot-mq.otr" "$out/soh.otr"
for f in oot.otr oot-mq.otr soh.otr; do
    if [ -f "$f" ]; then
        mv -f "$f" "$out/$f"
        echo "Created $out/$f"
    fi
done
if [ ! -f "$out/oot.otr" ] && [ ! -f "$out/oot-mq.otr" ]; then
    echo "Extraction failed: no oot.otr was created. See the messages above." >&2
    exit 1
fi
