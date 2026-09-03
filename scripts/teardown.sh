#!/usr/bin/env bash
# 銷毀測試環境
# 用法: bash scripts/teardown.sh [--volumes]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR/env"

echo "=== 停止容器 ==="
docker compose down 2>&1 | tail -3

if [[ "${1:-}" == "--volumes" ]]; then
    echo "=== 清除 keystore（需重新 setup_sros2.sh）==="
    rm -rf "$PROJECT_DIR/hardening/keystore"
    echo "✅ keystore 已清除"
fi

echo "✅ 環境已銷毀"
