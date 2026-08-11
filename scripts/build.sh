#!/bin/bash
set -eu

# 定義目錄結構
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
SRC="${GAWK_SRC:-$ROOT/upstream/gawk}"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"

echo "=== 1. 檢查原始碼環境 ==="
[ -f "$SRC/configure.ac" ] || { echo "錯誤: 找不到 $SRC/configure.ac" >&2; exit 1; }

# 確保輸出目錄存在
mkdir -p "$BUILD_DIR"

echo "=== 2. 執行 Autoreconf (產生 configure) ==="
if [ ! -x "$SRC/configure" ] || [ "$SRC/configure.ac" -nt "$SRC/configure" ]; then
    ( cd "$SRC" && autoreconf -fi )
fi

# 讀取外部傳入的 CONFIGURE_ARGS，若無則套用預設值
if [ -z "${CONFIGURE_ARGS:-}" ]; then
    CONFIGURE_ARGS="--disable-dependency-tracking --enable-shared --enable-extensions --with-readline --with-mpfr --enable-pma --disable-silent-rules"
fi

echo "=== 3. 執行 Configure ==="
echo "    CC=${CC:-gcc}"
echo "    CFLAGS=${CFLAGS:-}"
echo "    LDFLAGS=${LDFLAGS:-}"
echo "    ARGS=$CONFIGURE_ARGS"

( cd "$BUILD_DIR" && "$SRC/configure" $CONFIGURE_ARGS )

echo "=== 4. 執行編譯 (make -j${JOBS:-4}) ==="
make -C "$BUILD_DIR" -j"${JOBS:-4}"

# 驗證編譯結果
BIN="$BUILD_DIR/gawk"
[ -x "$BIN" ] || BIN="$BUILD_DIR/gawk.exe"
[ -x "$BIN" ] || { echo "錯誤: 編譯出的 gawk 執行檔不存在！" >&2; exit 1; }

echo "=== 5. 編編譯成功 ==="
"$BIN" --version | head -1
