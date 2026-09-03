# 自動化腳本

## 快速開始

```bash
# 一鍵完整流程（部署 → 基準攻擊 → 加固 → 加固後攻擊 → 驗證）
bash scripts/run_all.sh

# 或分步執行：
bash scripts/deploy.sh          # 建置並啟動隔離環境
bash scripts/start_nodes.sh     # 啟動無安全靶場節點
bash scripts/run_attacks.sh     # 執行全部攻擊測試
bash scripts/verify.sh          # 驗證加密 + 存取控制
bash scripts/teardown.sh        # 銷毀環境
```

## 腳本說明

| 腳本 | 用途 | 參數 |
|------|------|------|
| `deploy.sh` | 建置映像 + 啟動容器 + 驗證隔離 | `--rebuild` 強制重建映像 |
| `start_nodes.sh` | 啟動 victim 靶場節點 | `--secure` 以 SROS2 安全模式啟動 |
| `stop_nodes.sh` | 停止所有 victim 節點 | 無 |
| `run_attacks.sh` | 執行 2.1-2.7 全部攻擊測試 | `--label NAME` 結果報告標籤 |
| `verify.sh` | 驗證加密 + 存取控制 + 偵測 | `--detect` 同時執行偵測端 |
| `teardown.sh` | 停止並移除容器 | `--volumes` 同時清除 keystore |
| `run_all.sh` | 完整流程（上述全部） | 無 |

## 常用情境

### 情境 A：從零開始完整測試
```bash
bash scripts/run_all.sh
```

### 情境 B：只重跑攻擊測試（環境已部署）
```bash
# 無安全基準
bash scripts/start_nodes.sh
bash scripts/run_attacks.sh --label baseline

# 加固後
bash scripts/stop_nodes.sh
docker exec sectest-victim bash -lc 'bash /work/hardening/setup_sros2.sh'
bash scripts/start_nodes.sh --secure
docker exec sectest-victim bash -lc 'bash /work/hardening/firewall.sh apply'
bash scripts/run_attacks.sh --label hardened
```

### 情境 C：只驗證當前狀態
```bash
bash scripts/verify.sh --detect
```

### 情境 D：清理後重建
```bash
bash scripts/teardown.sh --volumes
bash scripts/deploy.sh --rebuild
```

## 產出物
- 攻擊報告：`results/baseline_YYYYMMDD_HHMMSS.md`、`results/hardened_YYYYMMDD_HHMMSS.md`
- 容器日誌：victim 容器內 `/tmp/tl_sec.log`、`/tmp/ps_sec.log`
