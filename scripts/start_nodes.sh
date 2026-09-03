#!/usr/bin/env bash
# 啟動 victim 靶場節點
# 用法: bash scripts/start_nodes.sh [--secure]
#   --secure: 以 SROS2 安全模式啟動（需先執行 setup_sros2.sh）
set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

SECURE=false
[[ "${1:-}" == "--secure" ]] && SECURE=true

echo "=== 停止舊節點 ==="
docker exec sectest-victim bash -lc 'pkill -9 -f "python3 /work/[v]ictim" 2>/dev/null; exit 0'
sleep 2

if $SECURE; then
    echo "=== 以 SROS2 安全模式啟動 ==="
    docker exec -d sectest-victim bash -lc 'source /opt/ros/jazzy/setup.bash && source /work/hardening/enable_security.sh && python3 /work/victim/talker_listener.py --ros-args --enclave / > /tmp/tl_sec.log 2>&1'
    docker exec -d sectest-victim bash -lc 'source /opt/ros/jazzy/setup.bash && source /work/hardening/enable_security.sh && python3 /work/victim/param_service_node.py --ros-args --enclave / > /tmp/ps_sec.log 2>&1'
    sleep 6
    echo "=== 安全節點狀態 ==="
    docker exec sectest-victim bash -lc 'tail -1 /tmp/tl_sec.log 2>/dev/null || echo "啟動中..."'
    docker exec sectest-victim bash -lc 'tail -1 /tmp/ps_sec.log 2>/dev/null || echo "啟動中..."'
else
    echo "=== 以無安全模式啟動 ==="
    docker exec -d sectest-victim bash -lc 'source /opt/ros/jazzy/setup.bash && python3 /work/victim/talker_listener.py > /tmp/tl.log 2>&1'
    docker exec -d sectest-victim bash -lc 'source /opt/ros/jazzy/setup.bash && python3 /work/victim/param_service_node.py > /tmp/ps.log 2>&1'
    sleep 6
    echo "=== 節點狀態 ==="
    docker exec sectest-victim bash -lc 'tail -1 /tmp/tl.log 2>/dev/null || echo "啟動中..."'
    docker exec sectest-victim bash -lc 'tail -1 /tmp/ps.log 2>/dev/null || echo "啟動中..."'
fi

echo ""
echo "✅ 靶場節點已啟動（模式: $($SECURE && echo '安全' || echo '無安全')）"
