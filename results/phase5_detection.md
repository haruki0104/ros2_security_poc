# 階段 5 偵測端結果

## 產出物
- `monitor/detect_anomaly.py`（v3）：Blue Team 被動偵測腳本

## 偵測能力
| 異常類型 | 偵測方式 | 結果 |
|---------|---------|------|
| 未知來源 IP | 白名單比對 | ✅ 正確識別 attacker 172.30.0.11 |
| 高速率來源 | pps threshold (>50) | ⚠️ scapy flood 速率低（1.2 pps），未觸發 |
| 探索埠洪水 | port range 計數 | ⚠️ 同上 |

## 驗收
- 正常環境：僅白名單 IP（victim/monitor/docker gateway）活動
- 攻擊期間：偵測到 172.30.0.11 為非白名單來源，告警
- victim 端確認 534 偽造封包抵達（2.7 攻擊仍有效於網路層）

## 限制與補強
- **scapy flood 速率低**：Python scapy `send()` 逐封包處理，實際攻擊者可用 C/Go 寫的高頻工具
- **偵測端應部署於 victim 端**：monitor 容器在交換式 bridge 上只能看到發往自己的封包；
  真實場景偵測應跑在 victim 主機本身
- **白名單維護**：需隨節點增減更新；動態環境建議改用 DDS-Security 的 participant 認證資訊

## 結論
偵測端可識別**未知來源**（最基礎的異常指標），但對低速率洪水需搭配 threshold 調校。
完整 Blue Team 應結合：
1. 來源白名單（本腳本）
2. 流量基線比對（需長期監控）
3. DDS-Security 日誌（participant 認證失敗記錄）
4. 網路層防火牆（任務 2 補強項目）
