#!/bin/zsh
# Distribution packages from the last macos/build.sh build:
#   output/ArmyAttack-macOS.dmg               universal app, ad-hoc signed
#   output/ArmyAttack-Windows-x86.zip   32-bit captive bundle
#
# usage: AIR_SDK=/path/to/AIRSDK_MacOS macos/package-dist.sh
#
# The Windows bundle needs HARMAN's AIR SDK for Windows (same version),
# extracted to macos/build/airsdk-win (lib/ and runtimes/air-captive/win/).
# adt builds a Windows bundle only on Windows: here it is run with Java's
# os.name set to Windows, which gets it as far as a signed .air package (with
# the native extension's Windows parts); its last step, converting that with
# the Windows-only naip32.exe, is replaced by assembling the bundle the way
# a captive Windows bundle is laid out: the package's contents, the runtime's
# "Adobe AIR" folder, and the runtime's CaptiveAppEntry.exe as the app's exe.
# (The exe keeps the runtime's generic icon.)
set -euo pipefail

HERE=${0:A:h}
OUT=$HERE/build
STAGE=$OUT/stage
DIST=${HERE:h}/output
WINSDK=$OUT/airsdk-win
APP="Army Attack"
[[ -d "$OUT/$APP.app" && -d $STAGE ]] || { echo "no build found; run macos/build.sh first"; exit 1; }
mkdir -p $DIST

# macOS: a disk image with the app and an Applications link.
rm -rf $DIST/mac $DIST/ArmyAttack-macOS.dmg
mkdir -p $DIST/mac
ditto "$OUT/$APP.app" "$DIST/mac/$APP.app"
ln -s /Applications $DIST/mac/Applications
hdiutil create -volname "$APP" -srcfolder $DIST/mac -ov -format UDZO $DIST/ArmyAttack-macOS.dmg >/dev/null
rm -rf $DIST/mac
echo "built $DIST/ArmyAttack-macOS.dmg"

# Windows.
NAIP=$WINSDK/lib/nai/bin/naip32.exe
CAPTIVE="$WINSDK/runtimes/air-captive/win/Adobe AIR"
[[ -f $NAIP && -d "$CAPTIVE" ]] || { echo "no Windows SDK in $WINSDK; skipping Windows"; exit 0; }
CAPTURE=$(mktemp -d)
mv $NAIP $NAIP.orig
trap 'mv -f $NAIP.orig $NAIP; rm -rf $CAPTURE' EXIT
cat > $NAIP <<EOF
#!/bin/sh
# Stand-in for naip32.exe -convert <package> <output> ...: keep the package.
cp "\$2" "$CAPTURE/package.air"
exit 0
EOF
chmod +x $NAIP
rm -rf $DIST/win
mkdir -p $DIST/win
(cd $STAGE && java -Dos.name="Windows 10" -Dos.arch=x86 -jar $WINSDK/lib/adt.jar -package \
  -storetype pkcs12 -keystore $OUT/cert.p12 -storepass "$(cat $OUT/cert.pass)" \
  -target bundle -arch x86 "$DIST/win/$APP" app.xml -extdir $OUT/ext \
  ArmyAttack.swf timelines.json config data AppIconsForPublish >/dev/null 2>&1) || true
[[ -f $CAPTURE/package.air ]] || { echo "adt did not produce the Windows package"; exit 1; }
rm -rf $DIST/win
mkdir -p "$DIST/win/$APP"
unzip -q $CAPTURE/package.air -d "$DIST/win/$APP"
cp -R "$CAPTIVE" "$DIST/win/$APP/"
cp "$CAPTIVE/Versions/1.0/Resources/CaptiveAppEntry.exe" "$DIST/win/$APP/$APP.exe"
rm -f $DIST/ArmyAttack-Windows-x86.zip
(cd $DIST/win && ditto -c -k --keepParent "$APP" ../ArmyAttack-Windows-x86.zip)
rm -rf $DIST/win
echo "built $DIST/ArmyAttack-Windows-x86.zip"
