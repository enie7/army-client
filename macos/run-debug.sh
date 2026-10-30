#!/bin/zsh
# Run the last build under the AIR debug launcher (adl), windowed, with
# trace() output and runtime errors printed to the terminal and to
# macos/build/debug.log. Run macos/build.sh first.
#
# usage: AIR_SDK=/path/to/AIRSDK_MacOS macos/run-debug.sh [game arguments...]
set -euo pipefail

OUT=${0:A:h}/build
: ${AIR_SDK:?set AIR_SDK to the AIR SDK for macOS}
[[ -f $OUT/stage/ArmyAttack.swf ]] || { echo "no build found; run macos/build.sh first"; exit 1; }

# adl wants native extensions unpacked, in a directory named like the .ane.
EXT=$OUT/ext-adl
rm -rf $EXT && mkdir -p $EXT/DiscordRPC.ane
unzip -q $OUT/ext/DiscordRPC.ane -d $EXT/DiscordRPC.ane

cd $OUT/stage
$AIR_SDK/bin/adl -profile extendedDesktop -extdir $EXT app.xml . -- "$@" 2>&1 | tee $OUT/debug.log
