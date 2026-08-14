#!/bin/bash
# 编译 DSH Shell 并组装成标准 .app 包
# 产物为 Universal Binary（arm64 + x86_64），最低支持 macOS 13.0
set -euo pipefail
cd "$(dirname "$0")"

APP="DSH Shell.app"
MIN_MACOS=13.0

build_arch() {
  local arch=$1
  echo "==> 编译 $arch ..."
  swiftc -O -parse-as-library -module-cache-path "$PWD/.module-cache-$arch" \
    -target "$arch-apple-macos$MIN_MACOS" \
    DSHShell.swift \
    -framework SwiftUI -framework WebKit -framework AppKit \
    -o "DSHShellBin-$arch"
}

# 先关掉正在运行的旧版本，避免替换文件时冲突
pkill -f "DSH Shell.app/Contents/MacOS" 2>/dev/null || true

build_arch arm64
build_arch x86_64

echo "==> 合并 Universal Binary..."
lipo -create DSHShellBin-arm64 DSHShellBin-x86_64 -output DSHShellBin

echo "==> 组装 $APP ..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp DSHShellBin "$APP/Contents/MacOS/DSH Shell"
cp Info.plist "$APP/Contents/Info.plist"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
rm DSHShellBin DSHShellBin-arm64 DSHShellBin-x86_64

echo "==> ad-hoc 签名..."
codesign --force --sign - "$APP"

echo "完成: $(pwd)/$APP"
