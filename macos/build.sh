#!/bin/zsh
# Build Army Attack for macOS from source, without Adobe Animate.
#
# The art lives only in the FLA, so the code is compiled with amxmlc and then
# injected into the release SWF (which still carries all the art).
#
# usage: AIR_SDK=/path/to/AIRSDK_MacOS macos/build.sh <release.swf>
#   release.swf: iArmyAirOfflineSavingv21_2.swf from the 23.2 Windows release
set -euo pipefail

HERE=${0:A:h}
REPO=${HERE:h}
SRC=$REPO/src
OUT=$HERE/build
TOOLS=$HERE/tools
RELEASE_SWF=${1:?usage: build.sh <release.swf>}
: ${AIR_SDK:?set AIR_SDK to the AIR SDK for macOS}
ADT=$AIR_SDK/bin/adt

mkdir -p $OUT

# 1. Compile-time stand-ins for classes that exist only in the FLA library.
#    Never linked into the game; the release SWF provides the real ones.
$AIR_SDK/bin/acompc -source-path $HERE/stubs -include-sources $HERE/stubs \
  -output $OUT/stubs.swc > $OUT/stubs.log 2>&1 || { cat $OUT/stubs.log; exit 1; }

# Starling (Stage3D renderer for the world), pinned, fetched on first build.
STARLING_TAG=v2.8
STARLING=$OUT/starling
if [[ ! -d $STARLING/starling/src ]]; then
  git clone -q --depth 1 --branch $STARLING_TAG https://github.com/Gamua/Starling-Framework.git $STARLING
fi

# 2. Compile the game code. Timeline classes (src/*_fla) are only referenced
#    from the SWF's symbol table, never from code, so include them by name.
SYMBOL_CLASSES=$(cd $SRC && find . -path './*_fla/*.as' | sed 's|^\./||; s|\.as$||; s|/|.|g' | sort | paste -sd, -)
$AIR_SDK/bin/amxmlc \
  -source-path+=$SRC \
  -source-path+=$STARLING/starling/src \
  -includes=$SYMBOL_CLASSES \
  -external-library-path+=$OUT/stubs.swc \
  -external-library-path+=$SRC/DiscordRPC.ane \
  -define=CONFIG::FLASH_AUTHORING,false \
  -define=CONFIG::USE_DISCORD_RPC,true \
  -define=CONFIG::BUILD_FOR_AIR,true \
  -define=CONFIG::NOT_BUILD_FOR_AIR,false \
  -define=CONFIG::BUILD_FOR_MOBILE_AIR,false \
  ${PROFILE:+-compiler.omit-trace-statements=false} ${PROFILE:+$([[ $PROFILE == debug ]] && echo -debug=true)} -swf-version=51 -default-size 1280 752 -default-frame-rate 40 \
  -o $OUT/code.swf $SRC/iArmyAir.as > $OUT/compile.log 2>&1 \
  || { grep -B1 -A3 -i 'error' $OUT/compile.log | head -60 || true; echo "compile failed: $OUT/compile.log"; exit 1; }
echo "compiled $OUT/code.swf"

# Timelines of the world art, for the GPU timeline player.
python3 $TOOLS/timelines.py $RELEASE_SWF $SRC/config/army_config_base.json $OUT/timelines.json

# 3. Art fixes, then put the new code in front of the release code.
python3 $TOOLS/patch_art.py $RELEASE_SWF $OUT/art.swf
python3 $TOOLS/inject.py $OUT/art.swf $OUT/code.swf $OUT/ArmyAttack.swf

# 4. Discord extension with a no-op "default" platform for macOS.
ANE_WORK=$OUT/ane
rm -rf $ANE_WORK && mkdir -p $ANE_WORK/src $ANE_WORK/default $OUT/ext
unzip -q -o $SRC/DiscordRPC.ane -d $ANE_WORK/src
cp $ANE_WORK/src/library.swf $ANE_WORK/default/
(cd $ANE_WORK/src && zip -q -X $ANE_WORK/DiscordRPC.swc catalog.xml library.swf)
$ADT -package -target ane $OUT/ext/DiscordRPC.ane $HERE/discordrpc-extension.xml \
  -swc $ANE_WORK/DiscordRPC.swc \
  -platform Windows-x86 -C $ANE_WORK/src/META-INF/ANE/Windows-x86 . \
  -platform default -C $ANE_WORK/default .

# 5. Package a macOS app bundle. adt requires a signing identity for the AIR
#    package itself; a local self-signed one is created on first use.
if [[ ! -f $OUT/cert.p12 ]]; then
  openssl rand -hex 12 > $OUT/cert.pass
  $ADT -certificate -cn "Army Attack macOS build" 2048-RSA $OUT/cert.p12 "$(cat $OUT/cert.pass)"
fi
STAGE=$OUT/stage
rm -rf $STAGE && mkdir -p $STAGE
cp $OUT/ArmyAttack.swf $HERE/app.xml $OUT/timelines.json $STAGE/
cp -R $SRC/config $SRC/data $SRC/AppIconsForPublish $STAGE/
rm -rf $STAGE/config/dev
APP="$OUT/Army Attack.app"
rm -rf $APP
(cd $STAGE && $ADT -package -storetype pkcs12 -keystore $OUT/cert.p12 -storepass "$(cat $OUT/cert.pass)" \
  -target bundle $APP app.xml -extdir $OUT/ext ArmyAttack.swf timelines.json config data AppIconsForPublish)

# 6. Ad-hoc code signature so macOS will launch it locally.
xattr -cr $APP
codesign --force --deep -s - $APP
codesign --verify --deep --strict $APP
echo "built $APP"
