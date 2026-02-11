#!/bin/bash
set -e

echo "Building XMusic..."

# Create build directory
mkdir -p build

# Compile Swift files
swiftc \
    -target arm64-apple-macos15.0 \
    -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
    -F /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
    -I /Library/Developer/CommandLineTools/usr/lib/swift \
    -L /Library/Developer/CommandLineTools/usr/lib/swift/macosx \
    -lswiftCore \
    -lswiftFoundation \
    -lswiftDarwin \
    -lswiftDispatch \
    -lswiftObjectiveC \
    -lswiftCoreFoundation \
    -framework Foundation \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    -framework AVFoundation \
    -o build/XMusic \
    XMusic/Sources/Main.swift \
    XMusic/Sources/Models/*.swift \
    XMusic/Sources/Views/*.swift

echo "Build complete!"
echo ""

# Create app bundle
echo "Creating XMusic.app bundle..."

APP_NAME="XMusic"
APP_BUNDLE="build/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

# 清理旧的应用包
rm -rf "${APP_BUNDLE}"

# 创建目录
mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

# 复制可执行文件
cp build/XMusic "${MACOS}/"

# 创建 Info.plist
cat > "${CONTENTS}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>XMusic</string>
    <key>CFBundleIdentifier</key>
    <string>com.xmusic.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>XMusic</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.png</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <false/>
    <key>LSBackgroundOnly</key>
    <false/>
</dict>
</plist>
EOF

# 创建 PkgInfo
echo "APPL????" > "${CONTENTS}/PkgInfo"

# Copy app icon
if [ -f "icons/AppIcon.png" ]; then
    cp "icons/AppIcon.png" "${RESOURCES}/AppIcon.png"
    echo "✅ App icon copied successfully!"
fi

# 删除多余的命令行可执行文件
rm -f "build/XMusic"
echo "✅ Cleaned up command line executable!"

echo "✅ ${APP_BUNDLE} created successfully!"
echo ""
echo "To run:"
echo "  1. Double-click build/XMusic.app in Finder"
echo "  2. Or run: open build/XMusic.app"
