# 貢獻指南

本專案為**授權範圍內**的 ROS2 安全測試靶場。貢獻前請先閱讀 [`AGENTS.md`](AGENTS.md) 與 [`PLAN.md`](PLAN.md)。

## 授權邊界（硬性）

⚠️ 僅在隔離環境對自有/授權目標測試。攻擊腳本必須跑在 `env/docker-compose.yml` 的 `internal: true` 網路內，**禁止**指向實體網路或未授權主機。任何違反此邊界的 PR 一律拒絕。

## 開發環境

```bash
bash scripts/deploy.sh          # 建置並啟動隔離環境
bash scripts/run_all.sh         # 完整流程驗證
```

## GitHub Flow

`main` 永遠保持可運作。所有變更走分支 → PR → 審查 → 合併。

```bash
git switch main && git pull
git switch -c feat/<簡述>        # 或 fix/ docs/ chore/
# ...實作 + 驗證...
git push -u origin feat/<簡述>
gh pr create --fill
```

### 分支命名

| 前綴 | 用途 | 範例 |
|------|------|------|
| `feat/` | 新功能 | `feat/cyclonedds-support` |
| `fix/` | 修 bug | `fix/23-firewall-ipv6` |
| `docs/` | 純文件 | `docs/threat-model` |
| `chore/` | 環境/CI | `chore/github-actions-ci` |

### Commit 訊息（Conventional Commits）

```
<type>: <簡述>

<選填內文>
```

`type` 為 `feat` / `fix` / `docs` / `chore` / `refactor` / `test`。issue 修復請帶編號，例如 `fix: 修正 pkill 自我匹配 (#12)`。

## 提交前檢查

```bash
# 1. Shell 腳本語法
for s in scripts/*.sh hardening/*.sh attacks/*.sh; do bash -n "$s"; done

# 2. shellcheck（CI 會跑，本地可選）
shellcheck scripts/*.sh hardening/*.sh 2>/dev/null

# 3. Python 語法
python3 -m py_compile attacks/*.py victim/*.py monitor/*.py

# 4. 功能驗證（如環境已部署）
bash scripts/verify.sh
```

## 安全紅線

- **絕不提交** `hardening/keystore/`（含 CA/節點私鑰，已於 `.gitignore` 排除）。clone 後以 `hardening/setup_sros2.sh` 重新產生。
- 攻擊腳本開頭需含：**目的、預期結果、成功判定條件**。
- 新增容器/IP 須同步更新 `env/fastdds_peers.xml`。

## 攻擊腳本慣例

放置目錄：攻擊 `attacks/`、靶場節點 `victim/`、加固 `hardening/`、偵測 `monitor/`、報告 `results/`。
