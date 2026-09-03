#!/usr/bin/env python3
"""
階段 5：Blue Team 異常偵測端（v3 — 修正 tcpdump 解析）

設計：SROS2 加密後 tshark RTPS 過濾器失效，以 tcpdump 原始計數取代。
偵測：(a) 白名單外來源 (b) 單一來源高速率 (c) 探索埠洪水

用法（monitor 容器內）：
    python3 /work/monitor/detect_anomaly.py [秒數] [白名單IP,逗號分隔]
"""
import subprocess
import sys
import os
import re
from collections import defaultdict


DOMAIN = int(os.environ.get('ROS_DOMAIN_ID', '42'))
BASE_PORT = 7400 + 250 * DOMAIN
HI_PORT = BASE_PORT + 250
IFACE = os.environ.get('IFACE', 'eth0')

# tcpdump 輸出格式：
#   HH:MM:SS.ffffff IP src.port > dst.port: ...
#   或帶 MAC/IP 協議前綴
IP_PATTERN = re.compile(r'(\d+\.\d+\.\d+\.\d+)\.(\d+) > (\d+\.\d+\.\d+\.\d+)\.(\d+):')


def capture(duration, bpf_filter=''):
    cmd = f'timeout {duration} tcpdump -i {IFACE} -nn -q {bpf_filter} 2>/dev/null'
    out = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=duration + 5).stdout
    src_counts = defaultdict(int)
    port_counts = defaultdict(int)
    for line in out.splitlines():
        m = IP_PATTERN.search(line)
        if not m:
            continue
        src_ip, _, dst_ip, dst_port = m.group(1), m.group(2), m.group(3), int(m.group(4))
        src_counts[src_ip] += 1
        port_counts[dst_port] += 1
    return src_counts, port_counts


def main():
    duration = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    whitelist = set(sys.argv[2].split(',')) if len(sys.argv) > 2 else {'172.30.0.10', '172.30.0.12'}
    rate_threshold = 50   # pps
    flood_threshold = 30  # pps on metatraffic ports

    print(f'=== Blue Team 異常偵測 (觀察 {duration}s) ===')
    print(f'白名單: {whitelist}')
    print(f'DDS 探索埠: {BASE_PORT}-{HI_PORT}')
    print()

    # 全流量
    print('--- 全流量分析 ---')
    src_all, _ = capture(duration)
    unknown = {ip: c for ip, c in src_all.items() if ip not in whitelist}
    fast = {ip: c / duration for ip, c in src_all.items() if c / duration > rate_threshold}

    if unknown:
        print(f'⚠️  偵測到 {len(unknown)} 個非白名單來源：')
        for ip, c in sorted(unknown.items(), key=lambda x: -x[1]):
            print(f'    {ip}: {c} 封包 ({c/duration:.1f} pps)')
    else:
        print('✅ 僅白名單 IP 活動')

    if fast:
        print(f'⚠️  高速率來源 (>{rate_threshold} pps)：')
        for ip, pps in sorted(fast.items(), key=lambda x: -x[1]):
            tag = '合法' if ip in whitelist else '🚨 可疑'
            print(f'    {ip}: {pps:.1f} pps [{tag}]')
    else:
        print(f'✅ 無高速率來源 (全 <{rate_threshold} pps)')
    print()

    # 探索埠
    print(f'--- 探索埠 ({BASE_PORT}-{HI_PORT}) 洪水偵測 ---')
    _, port_counts = capture(duration, bpf_filter=f'udp portrange {BASE_PORT}-{HI_PORT}')
    flood_ports = {p: c / duration for p, c in port_counts.items()
                   if BASE_PORT <= p <= HI_PORT and c / duration > flood_threshold}
    if flood_ports:
        print(f'⚠️  探索埠高速流量：')
        for p, pps in sorted(flood_ports.items(), key=lambda x: -x[1]):
            print(f'    port {p}: {pps:.1f} pps')
    else:
        print(f'✅ 探索埠流量正常 (全 <{flood_threshold} pps)')
    print()

    # 總結
    alerts = []
    if unknown:
        alerts.append(f'{len(unknown)} 個非白名單來源')
    if fast:
        alerts.append(f'{len(fast)} 個高速率來源')
    if flood_ports:
        alerts.append('探索埠洪水')

    if alerts:
        print(f'=== 🚨 告警：{", ".join(alerts)} ===')
        return 1
    else:
        print('=== ✅ 無異常告警 ===')
        return 0


if __name__ == '__main__':
    sys.exit(main())
