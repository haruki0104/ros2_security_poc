# 階段 4 加固後重跑攻擊 — 對照驗證

環境：SROS2 Enforce 模式，合法節點帶 `--enclave /` 憑證運行。
attacker **不帶憑證**（模擬外部攻擊者）重跑階段 2 全部攻擊。

## 加固前 / 後對照總表

| # | 測試案例 | 未加固（階段 2） | 加固後（階段 4） | 防護 |
|---|---------|----------------|----------------|------|
| 2.1 | 枚舉 | 列出全部節點/topic/service/參數 | 只見自身 daemon 的 rosout/parameter_events | ✅ 阻斷 |
| 2.2 | 封包嗅探 | 明文 `battery=...` 可見 | 明文 0 次、拓撲名稱 0 個（payload/discovery 加密） | ✅ 阻斷 |
| 2.3 | 未授權訂閱 | 竊取 5 筆敏感資料 | 訂閱 15s 收到 0 筆 | ✅ 阻斷 |
| 2.4 | 指令注入 | 致動器執行 191 筆惡意 5.0 | 送出 80+ 筆，致動器執行 5.0 共 0 次 | ✅ 阻斷 |
| 2.5 | 參數竄改/Service 濫用 | max_speed→99、safety 關閉 | `Node not found`、service call timeout | ✅ 阻斷 |
| 2.6 | Topic Flooding DoS | victim CPU 0.43%→109% | flood 期間 victim CPU 0.81%、致動器仍 1/秒 | ✅ 阻斷 |
| 2.7 | RTPS Discovery Flood | 偽造封包達探索埠 | 1557 封包仍抵達，但 CPU 0.50%、通訊正常 | ⚠️ 部分緩解 |

## 分析

### 完全阻斷（2.1–2.6）
DDS-Security 三支柱生效：
- **Authentication（PKI 互相認證）**：attacker 無 CA 簽發的憑證 → 無法加入 domain。
  → 2.4 注入的 publisher、2.6 flood 的 publisher 皆無法與 victim 配對。
- **Access Control（permissions.p7s）**：即使認證通過，也只能做 policy 允許的 pub/sub。
- **Encryption（governance ENCRYPT）**：discovery + data + metadata 全加密。
  → 2.1 枚舉、2.2 嗅探、2.3 訂閱皆取不到明文。

### 部分緩解（2.7）
- SROS2 運作在 DDS/RTPS 應用層，**無法阻止 IP/UDP 封包抵達**主機探索埠。
- 但認證握手失敗 → 偽造 participant 無法建立 → 無資源耗盡、無 participant 表膨脹。
- **補強建議**：搭配網路層防火牆（iptables 限制來源 IP）、rate limiting，
  或 DDS Discovery Server 架構縮小暴露面。

## 結論
啟用 SROS2 後，未授權者的「偵察→竊聽→注入→竄改→應用層 DoS」全鏈被阻斷。
唯一殘留風險為網路層封包洪水（2.7），需以防火牆/限流補強，非 SROS2 職責範圍。
