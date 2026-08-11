#!/bin/bash
set -eu

ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
DIST_DIR="$ROOT/dist"
TARGET="${TARGET:-unknown-platform}"

# 建立乾淨的輸出目錄
mkdir -p "$DIST_DIR"

# 偵測執行檔名稱
BIN_NAME="gawk"
BIN_PATH="$BUILD_DIR/$BIN_NAME"
if [ ! -f "$BIN_PATH" ]; then
    BIN_NAME="gawk.exe"
    BIN_PATH="$BUILD_DIR/$BIN_NAME"
fi

[ -f "$BIN_PATH" ] || { echo "錯誤: 打包失敗，找不到編譯產物" >&2; exit 1; }

# 建立一個臨時打包臨時夾
PKG_TMP="$ROOT/pkg_tmp"
rm -rf "$PKG_TMP" && mkdir -p "$PKG_TMP"
cp "$BIN_PATH" "$PKG_TMP/"

echo "=== 開始打包產物 ==="
cd "$DIST_DIR"

if [[ "$BIN_NAME" == *.exe ]]; then
    # Windows 平台打包成 .zip
    ARCHIVE_NAME="gawk-${TARGET}.zip"
    echo "打包成 $ARCHIVE_NAME..."
    ( cd "$PKG_TMP" && zip -r "$DIST_DIR/$ARCHIVE_NAME" * )
else
    # Linux / macOS 打包成 .tar.gz
    ARCHIVE_NAME="gawk-${TARGET}.tar.gz"
    echo "打包成 $ARCHIVE_NAME..."
    tar -czf "$ARCHIVE_NAME" -C "$PKG_TMP" "$BIN_NAME"
fi

# 計算 SHA256 校驗碼
echo "計算 SHA256SUM..."
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"
elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"
else
    echo "${ARCHIVE_NAME}" > "${ARCHIVE_NAME}.sha256" # 備用方案
fi

# 清理臨時資料夾
rm -rf "$PKG_TMP"
echo "打包完成！產物已存至 dist/ 目錄"
ls -la "$DIST_DIR"
