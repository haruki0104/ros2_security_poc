#!/usr/bin/env bash
# 階段 3：啟用 SROS2 安全設定（以 source 方式載入環境變數）。
#
# 用法（需要安全的合法節點端，先 source 再啟動節點）：
#   source /work/hardening/enable_security.sh
#   python3 /work/victim/talker_listener.py --ros-args --enclave /victim/talker_listener
#
# 關閉安全（回到基準）：unset 這些變數或開新 shell。

export ROS_SECURITY_KEYSTORE=/work/hardening/keystore
export ROS_SECURITY_ENABLE=true
# Enforce：無有效憑證/權限一律拒絕（對照 Permissive 只警告不阻擋）
export ROS_SECURITY_STRATEGY=Enforce

echo "[SROS2] 已啟用安全："
echo "  ROS_SECURITY_KEYSTORE=${ROS_SECURITY_KEYSTORE}"
echo "  ROS_SECURITY_ENABLE=${ROS_SECURITY_ENABLE}"
echo "  ROS_SECURITY_STRATEGY=${ROS_SECURITY_STRATEGY}"
echo "啟動節點時記得加：--ros-args --enclave <enclave路徑>"
