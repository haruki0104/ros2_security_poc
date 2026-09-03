# 隔離測試環境（階段 0）

三個容器全部掛在 `internal: true` 的 bridge network `lab` 上：容器間可互通，但無法連外網。

## 啟動
```bash
cd env
docker compose build
docker compose up -d
```

## 進入容器
```bash
docker exec -it sectest-victim   bash   # 靶場
docker exec -it sectest-attacker bash   # 攻擊端
docker exec -it sectest-monitor  bash   # 監控端
```
專案根目錄掛載於容器內 `/work`。

## 驗證隔離
```bash
# 應失敗（無對外路由）：
docker exec sectest-attacker ping -c1 -W2 8.8.8.8 || echo "OK: 無法連外網"
# 應成功（容器間互通）：
docker exec sectest-attacker ping -c1 victim
```

## 銷毀
```bash
docker compose down
```

## 說明
- `ROS_DOMAIN_ID=42`：與 host 預設 0 隔離，避免流量外溢。
- `ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET`：限制探索範圍在本子網。
- `cap_add: NET_RAW/NET_ADMIN`：供 scapy / tcpdump 封包層測試使用。
