#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST="$SCRIPT_DIR/dist"
PAL_SLAVE="$SCRIPT_DIR/StuntCarRacer.slave"
NTSC_SLAVE="$SCRIPT_DIR/StuntTrackRacer.slave"
OLD_DIR="StuntCarRacerHD"
NEW_DIR="StuntCarRacerUnleashed"

if [[ ! -f "$PAL_SLAVE" ]]; then
    echo "Error: $PAL_SLAVE not found. Build with 'make' on the Amiga first."
    exit 1
fi

if [[ ! -f "$NTSC_SLAVE" ]]; then
    echo "Error: $NTSC_SLAVE not found. Build with 'make' on the Amiga first."
    exit 1
fi

rm -rf "$DIST"
mkdir "$DIST"

curl -fsSL "https://whdload.de/games/StuntCarRacer.lha" -o "$DIST/StuntCarRacer.lha"
lha "xw=$DIST" "$DIST/StuntCarRacer.lha"
rm "$DIST/StuntCarRacer.lha"

curl -fsSL "https://whdload.de/games/StuntTrackRacer.lha" -o "$DIST/StuntTrackRacer.lha"
lha "xw=$DIST" "$DIST/StuntTrackRacer.lha"
rm "$DIST/StuntTrackRacer.lha"

mv "$DIST/$OLD_DIR" "$DIST/$NEW_DIR"
mv "$DIST/${OLD_DIR}.info" "$DIST/${NEW_DIR}.info"

rm -rf "$DIST/$NEW_DIR/Source"

cp "$SCRIPT_DIR/ReadMe" "$DIST/$NEW_DIR/ReadMe"
cp "$SCRIPT_DIR/Install" "$DIST/$NEW_DIR/Install"
cp "$PAL_SLAVE"  "$DIST/$NEW_DIR/StuntCarRacer.slave"
cp "$NTSC_SLAVE" "$DIST/$NEW_DIR/StuntTrackRacer.slave"

cp "$DIST/StuntTrackRacerHD/StuntTrackRacer.newicon"  "$DIST/$NEW_DIR/"
cp "$DIST/StuntTrackRacerHD/StuntTrackRacer.glowicon" "$DIST/$NEW_DIR/"

rm -rf "$DIST/StuntTrackRacerHD" "$DIST/StuntTrackRacerHD.info"

echo "Done: $DIST/"
