#!/usr/bin/env bash
# 執行全部攻擊測試（2.1-2.7）
# 用法: bash scripts/run_attacks.sh [--label LABEL]
#   --label: 結果標籤（預設: baseline 或 hardened）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_DIR/results"

LABEL="${2:-attacks}"
REPORT="$RESULTS_DIR/${LABEL}_$(date +%Y%m%d_%H%M%S).md"

echo "=========================================="
echo "  攻擊測試執行（標籤: $LABEL）"
echo "  報告輸出: $REPORT"
echo "  預估耗時: 約 2-3 分鐘（7 項串行）"
echo "=========================================="

ATTACKER="sectest-attacker"
VICTIM="sectest-victim"
MONITOR="sectest-monitor"

# 確保 attacker 無安全憑證
docker exec $ATTACKER bash -lc '
source /opt/ros/jazzy/setup.bash
unset ROS_SECURITY_ENABLE ROS_SECURITY_KEYSTORE ROS_SECURITY_STRATEGY
ros2 daemon stop >/dev/null 2>&1 || true'

cat > "$REPORT" << EOF
# 攻擊測試報告（${LABEL}）
執行時間: $(date '+%Y-%m-%d %H:%M:%S')

EOF

run_attack() {
    local num="$1" name="$2" cmd="$3"
    echo ""
    echo "--- [$num] $name ---"
    local output
    output=$(docker exec $ATTACKER bash -lc "$cmd" 2>&1) || true
    echo "$output" | tail -10
    echo "" >> "$REPORT"
    echo "## $num. $name" >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "$output" >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "" >> "$REPORT"
}

# 2.1 枚舉
run_attack "2.1" "節點/主題枚舉" \
    'source /opt/ros/jazzy/setup.bash && python3 /work/attacks/recon_enumerate.py'

# 2.2 嗅探
echo "--- [2.2] RTPS 封包嗅探 ---"
SNIFF_OUT=$(docker exec $ATTACKER bash -lc 'bash /work/attacks/recon_rtps_sniff.sh 10' 2>&1) || true
echo "$SNIFF_OUT" | tail -10
echo "" >> "$REPORT"
echo "## 2.2 RTPS 封包嗅探" >> "$REPORT"
echo '```' >> "$REPORT"
echo "$SNIFF_OUT" >> "$REPORT"
echo '```' >> "$REPORT"

# 2.3 未授權訂閱
run_attack "2.3" "未授權訂閱竊聽" \
    'source /opt/ros/jazzy/setup.bash && timeout 15 python3 /work/attacks/unauth_subscribe.py 2>&1 || true'

# 2.4 指令注入
echo "--- [2.4] 指令注入 ---"
docker exec $ATTACKER bash -lc 'source /opt/ros/jazzy/setup.bash && timeout 15 python3 /work/attacks/inject_cmd.py 2>&1' || true
sleep 1
INJECT_COUNT=$(docker exec $VICTIM bash -lc '
A=$(grep -c "linear.x=5.00" /tmp/tl_sec.log 2>/dev/null); A=${A:-0}
B=$(grep -c "linear.x=5.00" /tmp/tl.log 2>/dev/null); B=${B:-0}
if [ "$A" -ge "$B" ]; then echo "$A"; else echo "$B"; fi')
echo "  victim 致動器執行惡意指令數: $INJECT_COUNT"
echo "" >> "$REPORT"
echo "## 2.4 指令注入" >> "$REPORT"
echo "victim 執行惡意 linear.x=5.00 次數: **$INJECT_COUNT**" >> "$REPORT"
echo "" >> "$REPORT"

# 2.5 參數竄改
run_attack "2.5" "Parameter 竄改 + Service 濫用" \
    'source /opt/ros/jazzy/setup.bash && python3 /work/attacks/tamper_param.py 2>&1 || true'

# 2.6 Topic Flooding
echo "--- [2.6] Topic Flooding DoS ---"
CPU_BEFORE=$(docker stats --no-stream --format '{{.CPUPerc}}' $VICTIM)
docker exec -d $ATTACKER bash -lc 'source /opt/ros/jazzy/setup.bash && python3 /work/attacks/dos_topic_flood.py 10 /cmd_vel >/dev/null 2>&1'
sleep 4
CPU_DURING=$(docker stats --no-stream --format '{{.CPUPerc}}' $VICTIM)
sleep 7
echo "  victim CPU: 基準 ${CPU_BEFORE} → flood 期間 ${CPU_DURING}"
echo "" >> "$REPORT"
echo "## 2.6 Topic Flooding DoS" >> "$REPORT"
echo "victim CPU: 基準 ${CPU_BEFORE} → flood 期間 **${CPU_DURING}**" >> "$REPORT"
echo "" >> "$REPORT"

# 2.7 RTPS Flood
echo "--- [2.7] RTPS Discovery Flood ---"
docker exec -d $VICTIM bash -lc 'timeout 15 tcpdump -i eth0 -nn "udp and src host 172.30.0.11 and dst portrange 17900-18150" 2>/dev/null | wc -l > /tmp/flood_count.txt'
sleep 1
docker exec $ATTACKER bash -lc 'timeout 15 python3 /work/attacks/dos_rtps_flood.py 172.30.0.10 5000 >/dev/null 2>&1' || true
sleep 3
FLOOD_COUNT=$(docker exec $VICTIM bash -lc 'cat /tmp/flood_count.txt 2>/dev/null || echo 0')
CPU_AFTER=$(docker stats --no-stream --format '{{.CPUPerc}}' $VICTIM)
echo "  偽造封包抵達 victim: $FLOOD_COUNT"
echo "  victim CPU: ${CPU_AFTER}"
echo "" >> "$REPORT"
echo "## 2.7 RTPS Discovery Flood" >> "$REPORT"
echo "偽造封包抵達 victim: **$FLOOD_COUNT**" >> "$REPORT"
echo "victim CPU: **${CPU_AFTER}**" >> "$REPORT"

echo ""
echo "=========================================="
echo "  ✅ 攻擊測試完成"
echo "  報告: $REPORT"
echo "=========================================="
