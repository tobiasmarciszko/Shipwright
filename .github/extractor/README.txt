Ship of Harkinian 8.0.6 OTR extractor for macOS 11 and later (Intel)
====================================================================

Creates the oot.otr file the Wii U version of Ship of Harkinian 8.0.6
needs, from your own Ocarina of Time ROM. It also creates a matching
soh.otr.

Requirements
  - Python 3. If it is missing, run `xcode-select --install` in Terminal.
  - A ROM version supported by 8.0.6: PAL GameCube, PAL GameCube Master
    Quest, N64 PAL 1.0 / 1.1, or the GameCube debug ROMs.
    .z64, .n64 and .v64 files all work.

Usage
  1. Unzip this folder.
  2. In Terminal:
         bash /path/to/this/folder/extract.sh /path/to/your/rom.z64
  3. The files are written to the "output" folder inside this folder.
     A Master Quest ROM gives oot-mq.otr instead of oot.otr.

Copy oot.otr (and soh.otr) next to soh.rpx from the 8.0.6 Wii U release.
All three files must come from the same Ship of Harkinian version (8.0.6).
