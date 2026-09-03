# AGENTS.md

ROS2 Jazzy 安全測試靶場。授權範圍內的 SROS2 加固與攻擊測試專案。

## 授權邊界（硬性）
僅在隔離環境對自有/授權目標測試。攻擊腳本必須跑在 `env/docker-compose.yml` 的 `internal: true` 網路內，禁止指向實體網路或未授權主機。

## 計畫與進度
完整階段、產出物、驗收標準見 `PLAN.md`。執行規則：逐階段做，每階段結束暫停等使用者確認再繼續。

## 進度紀錄（每完成一階段更新此處）
- [x] 階段 0：隔離環境建置（映像 ros2-sectest:jazzy；容器 sectest-victim/attacker/monitor；隔離+互通+ROS2 已驗收）
- [x] 階段 1：基準靶場（victim/ 兩節點；tshark/echo 驗收完成；見 results/phase1_baseline.md）
- [x] 階段 2：攻擊測試案例（attacks/ 7 支全部 ✅；見 results/phase2_baseline.md）
- [x] 階段 3：SROS2 加固（keystore + 單一 enclave /；加密已驗收；見 results/phase3_hardening.md）
- [x] 階段 4：加固後重跑對照（2.1-2.6 全阻斷；2.7 部分緩解；見 results/phase4_hardened.md）
- [x] 階段 5：偵測端（monitor/detect_anomaly.py v3；可識別未知來源；見 results/phase5_detection.md）
- [x] 任務 2：2.7 網路層防火牆補強（hardening/firewall.sh；victim CPU 維持 0.48%；見 results/task2_firewall.md）

## 環境事實
- Host ROS2 Jazzy（`/opt/ros/jazzy`），Docker 29.1.3
- DDS：預設 Fast-DDS
- 測試 `ROS_DOMAIN_ID=42`：見 `env/docker-compose.yml`（避免與 host 預設 0 衝突）
- 容器固定 IP：victim 172.30.0.10 / attacker 172.30.0.11 / monitor 172.30.0.12
- **探索修正**：Docker bridge 上 Fast-DDS multicast 探索不通，改用 `env/fastdds_peers.xml`（unicast initial peers），經 `FASTRTPS_DEFAULT_PROFILES_FILE` 套用。新增容器/IP 須同步更新該 XML。

## 已知問題
- `aztarna` 未成功安裝：其相依 `uvloop`/`lxml`/`cffi` 在 jazzy(py3.12) 環境無預編譯 wheel，`pip` 由原始碼編譯失敗（缺 build 相依）。`env/Dockerfile` 以 `|| true` 容錯略過，不阻斷建置。階段 2 的節點/主題枚舉改用 `ros2` 原生指令 + tshark，功能不受影響。若日後需 aztarna：於容器內 `apt-get install build-essential libffi-dev libxml2-dev libxslt1-dev` 後再 `pip install aztarna`。
## SROS2 操作備忘
- keystore：`/work/hardening/keystore`；已建置（若遺失重跑 `bash /work/hardening/setup_sros2.sh`）
- 啟動安全節點：`source /work/hardening/enable_security.sh` 後加 `--ros-args --enclave /`
- policy 由 `ros2 security generate_policy` 從實際 graph 產生（手寫會漏隱藏服務）
- 驗證加密前務必 `pkill -9` 殺光殘留無安全節點，否則會誤判明文洩漏

## 慣例
- 攻擊腳本放 `attacks/`，靶場節點放 `victim/`，加固放 `hardening/`，測試報告放 `results/`
- 每個攻擊腳本開頭需含：目的、預期結果、成功判定條件

## 自動化腳本（scripts/）
一鍵化流程，詳見 `scripts/README.md`：
- `scripts/run_all.sh`：完整流程（部署→基準攻擊→加固→加固後攻擊→驗證）
- `scripts/deploy.sh`（`--rebuild`）、`start_nodes.sh`（`--secure`）、`stop_nodes.sh`
- `scripts/run_attacks.sh`（`--label NAME`，串行 7 項約 2-3 分）、`verify.sh`（`--detect`）、`teardown.sh`（`--volumes`）
- **踩雷**：`pkill -f` 切勿用會匹配自身命令行的 pattern（如 `talker_listener`），會讓 pkill 殺掉自己的 shell（exit 137）。改用括號 trick `python3 /work/[v]ictim`。
