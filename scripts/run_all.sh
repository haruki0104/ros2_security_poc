#!/usr/bin/env bash
# 完整測試流程：部署 → 基準攻擊 → 加固 → 加固後攻擊 → 驗證
# 用法: bash scripts/run_all.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════════════════╗"
echo "║  ROS2 Jazzy 安全測試 - 完整流程          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Step 1: 部署
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 1/6: 部署環境"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/deploy.sh"
echo ""

# Step 2: 啟動無安全節點
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 2/6: 啟動基準靶場（無安全）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/start_nodes.sh"
echo ""

# Step 3: 基準攻擊
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 3/6: 執行基準攻擊測試"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/run_attacks.sh" --label baseline
echo ""

# Step 4: 加固
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 4/6: SROS2 加固"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "--- 停止舊節點 ---"
bash "$SCRIPT_DIR/stop_nodes.sh"
echo ""
echo "--- 建立 keystore ---"
docker exec sectest-victim bash -lc 'bash /work/hardening/setup_sros2.sh'
echo ""
echo "--- 啟動安全節點 ---"
bash "$SCRIPT_DIR/start_nodes.sh" --secure
echo ""
echo "--- 啟用防火牆 ---"
docker exec sectest-victim bash -lc 'bash /work/hardening/firewall.sh apply'
echo ""

# Step 5: 加固後攻擊
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 5/6: 執行加固後攻擊測試"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/run_attacks.sh" --label hardened
echo ""

# Step 6: 驗證
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 6/6: 安全驗證"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/verify.sh" --detect
echo ""

echo "╔══════════════════════════════════════════╗"
echo "║  ✅ 完整測試流程完成                      ║"
echo "║                                          ║"
echo "║  報告位置: results/                      ║"
echo "║  環境狀態: 運行中（可用 teardown.sh 清除）║"
echo "╚══════════════════════════════════════════╝"
