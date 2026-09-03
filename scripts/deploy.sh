#!/usr/bin/env bash
# 部署隔離測試環境
# 用法: bash scripts/deploy.sh [--rebuild]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR/env"

REBUILD=false
[[ "${1:-}" == "--rebuild" ]] && REBUILD=true

echo "=========================================="
echo "  ROS2 Jazzy 安全測試 - 環境部署"
echo "=========================================="

if $REBUILD; then
    echo "[1/4] 重建映像檔..."
    docker compose build --no-cache 2>&1 | tail -3
else
    echo "[1/4] 建置映像檔（快取）..."
    docker compose build 2>&1 | tail -3
fi

echo "[2/4] 啟動容器..."
docker compose up -d 2>&1 | tail -3
sleep 2

echo "[3/4] 驗證隔離..."
if docker exec sectest-attacker ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then
    echo "  ❌ FAIL: attacker 可連外網（隔離失敗）"
    exit 1
else
    echo "  ✅ 隔離驗證：無法連外網"
fi

if docker exec sectest-attacker ping -c1 -W2 victim >/dev/null 2>&1; then
    echo "  ✅ 互通驗證：attacker → victim 可達"
else
    echo "  ❌ FAIL: attacker 無法連 victim"
    exit 1
fi

echo "[4/4] 工具檢查..."
docker exec sectest-attacker bash -lc 'which tshark tcpdump python3 >/dev/null 2>&1 && echo "  ✅ 工具就緒 (tshark/tcpdump/python3)"'
docker exec sectest-victim bash -lc 'which iptables >/dev/null 2>&1 && echo "  ✅ iptables 就緒"'

echo ""
echo "=========================================="
echo "  ✅ 部署完成"
echo "  victim:  172.30.0.10"
echo "  attacker: 172.30.0.11"
echo "  monitor: 172.30.0.12"
echo "=========================================="
