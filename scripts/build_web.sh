#!/bin/bash
# 本地建置 Web 版本
# 使用方式: bash scripts/build_web.sh
# 前提: 已安裝 Godot 4.2+ 且 export templates 已下載

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT_DIR="${PROJECT_DIR}/export/web"
GODOT="${GODOT_BIN:-godot}"

echo "=== 人生模擬器 - Web 建置 ==="
echo "專案目錄: ${PROJECT_DIR}"
echo "輸出目錄: ${EXPORT_DIR}"

# 檢查 Godot
if ! command -v "${GODOT}" &> /dev/null; then
    echo "錯誤: 找不到 Godot！"
    echo "請安裝 Godot 4.2+ 或設定 GODOT_BIN 環境變數"
    echo "例: GODOT_BIN=/path/to/godot bash scripts/build_web.sh"
    exit 1
fi

echo "Godot: $(${GODOT} --version 2>&1 | head -1)"

# 建立輸出目錄
mkdir -p "${EXPORT_DIR}"

# 匯入專案
echo "匯入專案資源..."
${GODOT} --headless --path "${PROJECT_DIR}" --import --quit 2>&1 || true
sleep 1

# 匯出
echo "匯出 Web 版本..."
${GODOT} --headless --path "${PROJECT_DIR}" --export-release "Web" "${EXPORT_DIR}/index.html"

echo ""
echo "=== 建置完成！==="
echo "輸出位置: ${EXPORT_DIR}/index.html"
echo ""
echo "測試方式（選一）:"
echo "  1. python3 -m http.server 8000 -d ${EXPORT_DIR}"
echo "     然後開啟 http://localhost:8000"
echo ""
echo "  2. npx serve ${EXPORT_DIR}"
echo ""
echo "注意: Godot Web 版需要 HTTPS 或 localhost 才能正常運行"
echo "      如果遇到 SharedArrayBuffer 問題，請使用支援 COOP/COEP 的伺服器"
