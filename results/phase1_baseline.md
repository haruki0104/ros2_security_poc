# 階段 1 基準靶場結果

## 靶場節點
- `victim_talker_listener`：發布 `/cmd_vel`(Twist)、`/sensor_data`(String)；訂閱 `/cmd_vel` 模擬致動器
- `victim_param_service`：參數 `max_speed`（預設 1.0）；服務 `/set_safety_mode`(SetBool)

## 環境修正（重要）
Docker bridge 上 Fast-DDS multicast 探索不通（attacker 發現不到 victim）。
解法：改用固定 IP + unicast initial peers。
- `env/fastdds_peers.xml`：列出 172.30.0.10/11/12 為 initial peers
- `env/docker-compose.yml`：固定 IP、subnet 172.30.0.0/24、`FASTRTPS_DEFAULT_PROFILES_FILE` 指向該 profile

## 基準驗收（未啟用 SROS2）
從 attacker 容器：
- `ros2 topic list` → 可見 `/cmd_vel`、`/sensor_data`
- `ros2 service list` → 可見 `/set_safety_mode`
- `ros2 topic echo --once /sensor_data` → 成功讀到 `battery=87%,gps=...`

結論：未加固狀態下，同網段任意參與者可完整列舉並讀取靶場資料，
作為階段 2 攻擊與階段 4 加固對照的基準。
