# ROS2 Jazzy 安全測試靶場

授權範圍內的 SROS2 加固與攻擊測試專案。在**網路隔離**的 Docker 環境中，驗證未啟用 SROS2 的攻擊面，以及啟用 SROS2 + 網路層防火牆後的防護效果。

> ⚠️ **授權邊界**：僅在隔離環境對自有/授權目標測試。攻擊腳本必須跑在 `env/docker-compose.yml` 的 `internal: true` 網路內，禁止指向實體網路或未授權主機。

## 快速開始

```bash
# 一鍵完整流程（部署 → 基準攻擊 → 加固 → 加固後攻擊 → 驗證）
make all          # 等同 bash scripts/run_all.sh

make help         # 列出所有便捷指令
```

分步執行與各腳本說明見 [`scripts/README.md`](scripts/README.md)；貢獻流程見 [`CONTRIBUTING.md`](CONTRIBUTING.md)。

## 目錄結構

```
robotics_study_materials/
├── env/          # 隔離環境（Dockerfile, docker-compose, fastdds_peers.xml）
├── victim/       # 靶場節點（talker_listener, param_service_node）
├── attacks/      # 攻擊測試案例 2.1-2.7
├── hardening/    # SROS2 加固 + iptables 防火牆
├── monitor/      # 偵測端（detect_anomaly.py）
├── scripts/      # 自動化流程腳本
├── results/      # 測試報告
├── AGENTS.md     # agent 接手指引 + 踩雷紀錄
└── PLAN.md       # 完整計畫與驗收標準
```

## 測試案例與防護對照

| # | 攻擊 | 未加固 | 加固後（SROS2 + 防火牆） |
|---|------|--------|------------------------|
| 2.1 | 節點/主題枚舉 | 全部可見 | ✅ 阻斷 |
| 2.2 | RTPS 封包嗅探 | 明文可見 | ✅ 加密 |
| 2.3 | 未授權訂閱 | 竊取資料 | ✅ 阻斷 |
| 2.4 | 指令注入 | 致動器失控 | ✅ 阻斷 |
| 2.5 | 參數竄改 | 成功竄改 | ✅ 阻斷 |
| 2.6 | Topic Flooding | CPU 109% | ✅ CPU <1% |
| 2.7 | RTPS Flood | 封包達埠 | ⚠️ 限流緩解 |

## 防禦鏈

```
偵測（detect_anomaly.py）→ 限流（iptables）→ 認證（SROS2 PKI）→ 加密（DDS-Security）
```

## 環境事實

- Host ROS2 Jazzy（`/opt/ros/jazzy`）、Docker 29.1.3、DDS 預設 Fast-DDS
- 容器固定 IP：victim 172.30.0.10 / attacker 172.30.0.11 / monitor 172.30.0.12
- `ROS_DOMAIN_ID=42`；Docker bridge multicast 不通，改用 unicast peers（`env/fastdds_peers.xml`）
