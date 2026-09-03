#!/usr/bin/env bash
# 任務 2：victim 端網路層防火牆（iptables 限流）
#
# 目的：補強 SROS2 無法阻擋的網路層封包洪水（2.7 攻擊）。
# 策略：
#   1. 白名單 IP 直接放行（合法 participant：victim 自身、monitor）
#   2. 非白名單 IP 對 DDS 探索埠限流（hashlimit: 100 pkt/s, burst 50）
#   3. 超過限流的封包 DROP
#
# 用法（victim 容器內，需 NET_ADMIN）：
#   bash /work/hardening/firewall.sh [apply|status|flush]
set -e

DOMAIN="${ROS_DOMAIN_ID:-42}"
BASE_PORT=$((7400 + 250 * DOMAIN))
HI_PORT=$((BASE_PORT + 250))

# 合法 participant IP（白名單）
WHITELIST="172.30.0.10 172.30.0.12"

flush_rules() {
    iptables -F ROS2_RATELIMIT 2>/dev/null || true
    iptables -D INPUT -p udp --dport ${BASE_PORT}:${HI_PORT} -j ROS2_RATELIMIT 2>/dev/null || true
    iptables -X ROS2_RATELIMIT 2>/dev/null || true
    echo "[firewall] 已清除 ROS2_RATELIMIT 鏈"
}

apply_rules() {
    flush_rules
    iptables -N ROS2_RATELIMIT
    # 白名單直接放行
    for ip in $WHITELIST; do
        iptables -A ROS2_RATELIMIT -s "$ip" -j ACCEPT
    done
    # 非白名單：hashlimit 限流（100 pkt/s, burst 50, 依來源 IP 分桶）
    iptables -A ROS2_RATELIMIT -p udp -m hashlimit \
        --hashlimit-name rtps_flood \
        --hashlimit-upto 100/sec \
        --hashlimit-burst 50 \
        --hashlimit-mode srcip \
        -j ACCEPT
    # 超過限流：DROP
    iptables -A ROS2_RATELIMIT -j DROP
    # 掛到 INPUT 鏈（僅針對 DDS 探索埠範圍）
    iptables -A INPUT -p udp --dport ${BASE_PORT}:${HI_PORT} -j ROS2_RATELIMIT
    echo "[firewall] 已套用限流規則（探索埠 ${BASE_PORT}-${HI_PORT}）"
    echo "[firewall] 白名單: $WHITELIST"
    echo "[firewall] 限流: 100 pkt/s per src, burst 50"
}

show_status() {
    echo "=== ROS2_RATELIMIT 鏈 ==="
    iptables -L ROS2_RATELIMIT -n -v 2>/dev/null || echo "(鏈不存在)"
}

case "${1:-apply}" in
    apply) apply_rules ;;
    flush) flush_rules ;;
    status) show_status ;;
    *) echo "用法: $0 [apply|flush|status]"; exit 1 ;;
esac
