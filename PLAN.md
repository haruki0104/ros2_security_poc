# ROS2 Jazzy 安全測試計畫（SROS2 + 攻擊測試案例）

## 目標
在網路隔離環境中建立可控的 ROS2 Jazzy 靶場，逐一驗證：未啟用 SROS2 的攻擊面 → 啟用 SROS2 後的防護效果。

## 授權與安全前提
- ⚠️ 僅用於自有或已獲書面授權的目標。對未授權系統執行這些測試屬違法行為。
- ⚠️ 全程在隔離 docker network（`internal: true`，無對外路由）中進行。
- ⚠️ 限定 `ROS_DOMAIN_ID` 與探索範圍，避免 DDS multicast 外洩到實體網路。
- ⚠️ 攻擊腳本僅作用於本測試網段。

## 環境事實
- Host: ROS2 Jazzy 已安裝於 `/opt/ros/jazzy`；`ROS_DISTRO=jazzy`
- Docker 29.1.3 可用
- DDS: 預設 Fast-DDS；SROS2 尚未啟用

## 階段

### 階段 0：隔離環境建置
- `env/docker-compose.yml`：3 容器 `victim` / `attacker` / `monitor`，掛在 `internal: true` bridge network
- `env/Dockerfile`：基於 `ros:jazzy`，加裝 scapy、tcpdump、tshark、aztarna 等
- `env/README.md`：啟動/銷毀指令
- 驗收：三容器互通；`docker exec attacker ping -c1 8.8.8.8` 失敗（確認隔離）

### 階段 1：基準靶場（未啟用 SROS2）
- `victim/talker_listener.py`：合法 pub/sub（`/cmd_vel`、`/sensor_data`）
- `victim/param_service_node.py`：帶 parameter 與 service 的節點
- 驗收：合法通訊正常，作為對照基準

### 階段 2：攻擊測試案例（對未加固系統）
| # | 測試案例 | 檔案 | 手法 |
|---|---------|------|------|
| 2.1 | 節點/主題枚舉 | `attacks/recon_enumerate.py` | ros2 node/topic/service list |
| 2.2 | RTPS 探索封包嗅探 | `attacks/recon_rtps_sniff.sh` | tshark 抓 port 7400+ |
| 2.3 | 未授權訂閱 | `attacks/unauth_subscribe.py` | echo 敏感 topic |
| 2.4 | 指令注入 | `attacks/inject_cmd.py` | 高頻覆寫 /cmd_vel |
| 2.5 | Parameter 竄改 | `attacks/tamper_param.py` | ros2 param set |
| 2.6 | Topic Flooding DoS | `attacks/dos_topic_flood.py` | 大 payload 高頻發布 |
| 2.7 | RTPS Discovery Flood | `attacks/dos_rtps_flood.py` | scapy 偽造大量 participant |
- 驗收：每項結果記錄至 `results/phase2_baseline.md`

### 階段 3：啟用 SROS2 加固
- `hardening/setup_sros2.sh`：建立 keystore、CA、為各節點簽發憑證
- `hardening/policies/policy.xml`：存取控制策略
- `hardening/enable_security.sh`：設定 `ROS_SECURITY_ENABLE=true`、`ROS_SECURITY_STRATEGY=Enforce`、keystore 路徑
- 驗收：合法節點在加密+認證下正常通訊；tshark 確認 RTPS payload 已加密

### 階段 4：加固後重跑攻擊（對照驗證）
- 重跑階段 2 所有腳本
- `results/phase4_hardened.md`：攻擊前/後對照表
- 驗收：未授權存取被拒、封包已加密、注入/竄改失敗

### 階段 5：偵測端（Blue Team，選配）
- `monitor/detect_anomaly.py`：監控異常 participant、流量告警

## 目錄結構
```
robotics_study_materials/
├── env/            # 隔離環境
├── victim/         # 靶場節點
├── attacks/        # 攻擊測試案例 2.1-2.7
├── hardening/      # SROS2 加固
├── monitor/        # 偵測端
├── results/        # 測試報告
├── AGENTS.md       # agent 接手指引
└── PLAN.md         # 本計畫
```

## 執行方式
逐階段執行，每階段結束後暫停，待使用者確認再繼續。
