# 階段 2 攻擊測試結果（未啟用 SROS2 — 基準）

測試環境：隔離 docker network，domain 42，Fast-DDS 預設無安全。
attacker(172.30.0.11) 對 victim(172.30.0.10) 執行。

## 結果總表

| # | 測試案例 | 腳本 | 結果 | 關鍵證據 |
|---|---------|------|------|---------|
| 2.1 | 節點/主題/服務/參數枚舉 | `recon_enumerate.py` | ✅ 成功 | 列出 2 節點、/cmd_vel、/sensor_data、/set_safety_mode、參數 max_speed |
| 2.2 | RTPS 封包嗅探 | `recon_rtps_sniff.sh` | ✅ 成功 | 封包中見明文 `battery=87%,gps=25.033,121.565` |
| 2.3 | 未授權訂閱竊聽 | `unauth_subscribe.py` | ✅ 成功 | 竊取 5 筆 /sensor_data 敏感資料 |
| 2.4 | 控制指令注入 | `inject_cmd.py` | ✅ 成功 | 致動器執行 191 筆惡意 linear.x=5.0 |
| 2.5 | Parameter 竄改 + Service 濫用 | `tamper_param.py` | ✅ 成功 | max_speed 改成 99.0、safety_mode 關閉 |
| 2.6 | Topic Flooding DoS | `dos_topic_flood.py` | ✅ 成功* | flood /cmd_vel：victim CPU 0.43%→109%，致動器 800+ 指令/秒 |
| 2.7 | RTPS Discovery Flood | `dos_rtps_flood.py` | ✅ 成功 | ~1400 偽造封包送達探索埠 17900/17910/7400 |

## 重要發現（實驗過程學到的）

1. **探索需 unicast**：Docker bridge 上 Fast-DDS multicast 探索不穩，改用固定 IP + `fastdds_peers.xml` unicast initial peers（見階段 1）。

2. **DoS 必須打「有訂閱者」的 topic**：
   - flood `/sensor_data`（victim 只發布、無訂閱）→ victim CPU 幾乎不動（0.38%），DDS 不投遞給無 reader 的一端。
   - flood `/cmd_vel`（victim 有訂閱）→ victim CPU 飆到 109%，合法巡航指令被淹沒。
   - 教訓：攻擊者需先枚舉（2.1）找出目標訂閱的 topic 才能有效 DoS。

3. **明文洩漏需資料流經嗅探點**：交換式 bridge 上，unicast 資料只到目的地；攻擊者以訂閱者身分讓資料流到本機後即可在封包層看到明文（無 DDS-Security 加密）。

4. **無來源驗證**：偽造來源 IP/GUID 的 RTPS 封包可直接送達 victim 探索埠，未被過濾。

## 結論
未啟用 SROS2 時，同網段任意參與者可完成：偵察 → 竊聽 → 注入 → 竄改 → DoS 全鏈。
這些即為階段 4 加固後須被阻斷的項目。
