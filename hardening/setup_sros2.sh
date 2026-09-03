#!/usr/bin/env bash
# 階段 3：建立 SROS2 keystore、CA、各節點 enclave 與存取控制憑證。
#
# 在 victim 容器內執行一次即可（keystore 位於 /work bind-mount，全容器共享）。
# 注意：真實情境中私鑰只會存在合法節點主機；此處共享僅為實驗方便，
#       攻擊測試時 attacker 會「不使用」這些憑證以模擬外部攻擊者。
#
# 用法（victim 容器內）：
#   bash /work/hardening/setup_sros2.sh
set -e
source /opt/ros/jazzy/setup.bash

KEYSTORE=/work/hardening/keystore
POLICY=/work/hardening/policies/policy.xml

echo "=== 1. 建立 keystore (含 CA) ==="
rm -rf "${KEYSTORE}"
ros2 security create_keystore "${KEYSTORE}"

# 注意：ROS2 節點會自動建立隱藏服務（~/get_type_description、
# 參數服務等）。手寫 policy 很容易漏掉，導致 Enforce 模式下
# 節點 create_service 失敗。故採官方推薦工作流：先以無安全模式
# 啟動節點，再用 generate_policy 從實際 graph 擷取完整需求：
#   ros2 security generate_policy ${POLICY}
# 本專案已產生好的 policy 即來自此（單一 enclave "/"）。
echo "=== 2. 依 policy 產生 enclave 金鑰與權限憑證 (enclave /) ==="
ros2 security generate_artifacts \
    -k "${KEYSTORE}" \
    -p "${POLICY}" \
    -e /

echo "=== 3. 列出已建立的 enclave ==="
ros2 security list_enclaves "${KEYSTORE}"

echo ""
echo "完成。keystore: ${KEYSTORE}"
echo "下一步：source /work/hardening/enable_security.sh 後啟動節點。"
