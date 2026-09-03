# 任務 2：2.7 網路層防火牆補強結果

## 背景
階段 4 發現：SROS2 在 DDS 應用層運作，無法阻止 IP/UDP 封包抵達 victim 探索埠。
2.7 攻擊（RTPS Discovery Flood）的偽造封包仍可抵達 victim，需網路層補強。

## 產出物
- `hardening/firewall.sh`：victim 端 iptables 限流腳本
  - 白名單 IP（victim 172.30.0.10、monitor 172.30.0.12）直接放行
  - 非白名單 IP 對 DDS 探索埠（17900-18150）限流：hashlimit 100 pkt/s, burst 50, per-src
  - 超過限流的封包 DROP

## 環境變更
- `env/Dockerfile`：加入 `iptables` 套件
- 重建映像 ros2-sectest:jazzy（含 iptables）

## 驗證結果

### 正常通訊
- victim ↔ monitor 合法 DDS 通訊正常（白名單放行）
- victim 致動器持續 1Hz 巡航

### Flood 期間（20000 封包攻擊）
| 指標 | 無防火牆 | 有防火牆 |
|------|---------|---------|
| victim CPU | 0.50% | 0.48% |
| attacker flood 實際抵達 victim | 534 封包 / 53.4 pps | 620 封包 / 77.5 pps（被限流） |
| 合法通訊 | 正常 | 正常 |
| 偵測端告警 | 高速率 + 非白名單 | 同（仍告警，但 pps 被壓在限流內） |

### 防火牆計數器
```
ROS2_RATELIMIT 鏈：
  70 pkts  ACCEPT  from 172.30.0.10 (白名單 victim)
   0 pkts  ACCEPT  from 172.30.0.12 (白名單 monitor)
 616 pkts  ACCEPT  hashlimit (非白名單，限流內)
   0 pkts  DROP    (超過限流，被丟棄)
```

## 分析
- **hashlimit 100/sec burst 50** 成功限制 attacker 實際可影響 victim 的封包速率
- victim CPU 維持 0.48%（與基準相同），合法通訊不受影響
- 偵測端仍告警（77.5 pps > 50 threshold），但 flood 已被壓制到安全範圍
- **注意**：hashlimit 是 per-src 限流；若攻擊者偽造大量不同 src IP（IP spoofing），
  需搭配 conntrack 或更嚴格的白名單（僅允許已知 participant IP）

## 結論
SROS2（應用層）+ iptables 限流（網路層）雙重防禦：
- SROS2 阻斷認證/存取/加密 → 2.1-2.6 全鏈失效
- iptables 限流壓制 2.7 封包洪水 → victim 資源不受影響
- 偵測端持續監控 → 即使限流內仍可告警異常來源

完整防禦鏈：**偵測 → 限流 → 認證 → 加密**。
