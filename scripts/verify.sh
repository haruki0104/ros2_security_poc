#!/usr/bin/env bash
# 驗證：加密檢查 + 偵測端執行
# 用法: bash scripts/verify.sh [--detect]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  安全驗證"
echo "=========================================="

# 1. 加密驗證
echo ""
echo "--- [1] 加密驗證（monitor 被動嗅探 12s）---"
ENCRYPT_RESULT=$(docker exec sectest-monitor bash -lc '
timeout 12 tcpdump -i eth0 -A -s0 udp 2>/dev/null > /tmp/verify_cap.txt
BATTERY=$(grep -ac "battery=" /tmp/verify_cap.txt); BATTERY=${BATTERY:-0}
TOPIC=$(grep -aoE "sensor_data|cmd_vel|victim_[a-z]+" /tmp/verify_cap.txt | sort -u | wc -l | tr -d " ")
echo "明文 battery= 出現: $BATTERY 次"
echo "明文拓撲名稱: $TOPIC 個"
if [ "$BATTERY" -eq 0 ] && [ "$TOPIC" -eq 0 ]; then
    echo "✅ 加密驗證通過"
else
    echo "❌ 加密驗證失敗（仍有明文洩漏）"
fi')
echo "$ENCRYPT_RESULT"

# 2. 未授權存取驗證
echo ""
echo "--- [2] 未授權存取驗證（attacker 無憑證）---"
ACCESS_RESULT=$(docker exec sectest-attacker bash -lc '
source /opt/ros/jazzy/setup.bash
unset ROS_SECURITY_ENABLE ROS_SECURITY_KEYSTORE ROS_SECURITY_STRATEGY
NODES=$(timeout 6 ros2 node list 2>/dev/null | grep -c victim); NODES=${NODES:-0}
TOPICS=$(timeout 6 ros2 topic list 2>/dev/null | grep -cE "cmd_vel|sensor_data"); TOPICS=${TOPICS:-0}
echo "attacker 可見 victim 節點數: $NODES"
echo "attacker 可見敏感 topic 數: $TOPICS"
if [ "$NODES" -eq 0 ] && [ "$TOPICS" -eq 0 ]; then
    echo "✅ 存取控制驗證通過"
else
    echo "❌ 存取控制驗證失敗"
fi')
echo "$ACCESS_RESULT"

# 3. 偵測端（選配）
if [[ "${1:-}" == "--detect" ]]; then
    echo ""
    echo "--- [選配] 偵測端執行 ---"
    docker exec sectest-victim bash -lc 'python3 /work/monitor/detect_anomaly.py 10 172.30.0.10,172.30.0.12,172.30.0.1' || true
fi

# 4. 防火牆狀態
echo ""
echo "--- [3] 防火牆狀態 ---"
docker exec sectest-victim bash -lc 'bash /work/hardening/firewall.sh status 2>/dev/null || echo "防火牆未啟用"'

echo ""
echo "=========================================="
echo "  驗證完成"
echo "=========================================="
