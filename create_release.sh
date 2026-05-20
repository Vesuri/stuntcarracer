#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_LHA_URL="https://whdload.de/games/StuntCarRacer.lha"
OUTPUT="$SCRIPT_DIR/StuntCarRacerUnleashed.lha"
PAL_SLAVE="$SCRIPT_DIR/StuntCarRacer.slave"
NTSC_SLAVE="$SCRIPT_DIR/StuntTrackRacer.slave"
OLD_DIR="StuntCarRacerHD"
NEW_DIR="StuntCarRacerUnleashed"

if ! command -v olha &>/dev/null; then
    echo "Error: olha not found. Build from https://codeberg.org/MastaTabs/olha"
    exit 1
fi

if [[ ! -f "$PAL_SLAVE" ]]; then
    echo "Error: $PAL_SLAVE not found. Build with 'make' on the Amiga first."
    exit 1
fi

if [[ ! -f "$NTSC_SLAVE" ]]; then
    echo "Error: $NTSC_SLAVE not found. Build with 'make' on the Amiga first."
    exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

curl -fsSL "$BASE_LHA_URL" -o "$WORK/StuntCarRacer.lha"
lha "xw=$WORK" "$WORK/StuntCarRacer.lha"

curl -fsSL "https://whdload.de/games/StuntTrackRacer.lha" -o "$WORK/StuntTrackRacer.lha"
lha "xw=$WORK" "$WORK/StuntTrackRacer.lha"

mv "$WORK/$OLD_DIR" "$WORK/$NEW_DIR"
mv "$WORK/${OLD_DIR}.info" "$WORK/${NEW_DIR}.info"

rm -rf "$WORK/$NEW_DIR/Source"

cp "$SCRIPT_DIR/StuntCarRacer.readme" "$WORK/$NEW_DIR/ReadMe"
cp "$SCRIPT_DIR/Install"            "$WORK/$NEW_DIR/Install"
cp "$PAL_SLAVE"  "$WORK/$NEW_DIR/StuntCarRacer.slave"
cp "$NTSC_SLAVE" "$WORK/$NEW_DIR/StuntTrackRacer.slave"

cp "$WORK/StuntTrackRacerHD/StuntTrackRacer.newicon"  "$WORK/$NEW_DIR/"
cp "$WORK/StuntTrackRacerHD/StuntTrackRacer.glowicon" "$WORK/$NEW_DIR/"

rm -f "$OUTPUT"
(cd "$WORK" && olha c "$OUTPUT" "${NEW_DIR}.info" "$NEW_DIR")

echo "Created: $OUTPUT"
