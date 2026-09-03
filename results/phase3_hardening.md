# 階段 3 SROS2 加固結果

全程於 docker 隔離環境（同階段 0-2）。keystore 位於 `/work/hardening/keystore`（bind-mount）。

## 產出物
- `hardening/setup_sros2.sh`：建立 keystore/CA + 產生 enclave 憑證
- `hardening/policies/policy.xml`：存取控制策略（由 `generate_policy` 從實際 graph 產生）
- `hardening/policies/policy_generated.xml`：原始自動產生檔（保留）
- `hardening/enable_security.sh`：設定 `ROS_SECURITY_ENABLE=true`、`STRATEGY=Enforce`、keystore 路徑

## governance.xml 保護設定（預設）
- `discovery_protection_kind=ENCRYPT`
- `liveliness_protection_kind=ENCRYPT`
- `rtps_protection_kind=SIGN`
- 每 topic：`metadata_protection_kind=ENCRYPT`、`data_protection_kind=ENCRYPT`
- `enable_join_access_control=true`、讀/寫存取控制皆 true

## 啟動方式
```bash
source /work/hardening/enable_security.sh
python3 /work/victim/talker_listener.py  --ros-args --enclave /
python3 /work/victim/param_service_node.py --ros-args --enclave /
```

## 驗收
- 合法節點日誌：`Found security directory: .../keystore/enclaves`，通訊正常（0.2 巡航持續）
- 加密驗證（monitor 被動嗅探 15s，乾淨狀態）：
  - 明文 `battery=` 出現 **0 次**
  - 明文拓撲名稱（sensor_data/cmd_vel/victim_*）**0 個**
- attacker 無憑證：連 `/sensor_data` 型別都無法取得（探索受保護）

## 踩雷紀錄（重要）
1. **手寫 policy 會漏掉隱藏服務**：每個節點自動建立 `~/get_type_description`、6 個參數服務等；
   Enforce 模式下漏授權 → 節點 `create_service` 失敗。解法：用 `ros2 security generate_policy`
   從實際 graph 自動產生完整 policy。
2. **殘留無安全節點造成假明文**：先前的無安全節點未殺乾淨，持續明文發布，
   一度誤判「加密失效」。務必 `pkill -9` 確認清空後再驗證加密。
