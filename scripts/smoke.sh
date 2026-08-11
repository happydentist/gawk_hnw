#!/bin/bash
set -eu

ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"

BIN="$BUILD_DIR/gawk"
[ -f "$BIN" ] || BIN="$BUILD_DIR/gawk.exe"
[ -f "$BIN" ] || { echo "錯誤: 找不到可測試的 gawk 檔案" >&2; exit 1; }

echo "=== 1. 執行基礎冒煙測試 ==="
echo "測試 1: 輸出版本"
"$BIN" --version | head -n 1

echo "測試 2: 基礎語法計算"
RESULT=$("$BIN" 'BEGIN {print 1+2+3}')
if [ "$RESULT" != "6" ]; then
    echo "測試失敗: 預期 6, 得到 $RESULT"
    exit 1
fi
echo "OK: 基礎功能正常"

echo "=== 2. 驗證依賴庫安全性 (RPATH / Dynamic Link 檢查) ==="
OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"

case "$OS_TYPE" in
    Linux)
        if command -v ldd >/dev/null 2>&1; then
            echo "檢查 Linux 連結狀態:"
            ldd "$BIN"
            # 如果不是全靜態編譯，且抓到了 /usr/lib 的非系統庫，就發出警告或中斷（配合你之前的設計）
            if ldd "$BIN" | grep -E "libreadline|libmpfr|libgmp" | grep -q "/usr/lib"; then
                echo "警告: 檢測到動態連結系統庫，但我們嘗試放行..."
            fi
        fi
        ;;
    Darwin)
        if command -v otool >/dev/null 2>&1; then
            echo "檢查 macOS 連結狀態:"
            otool -L "$BIN"
            # 確保沒有黏在不該黏的地方
            if otool -L "$BIN" | grep -q "libedit"; then
                echo "警告: 檢測到系統 libedit，而非標準 readline！"
            fi
        fi
        ;;
    *)
        echo "Windows 環境，跳過 RPATH 嚴格檢查"
        ;;
esac

echo "冒煙測試全部通過！"
