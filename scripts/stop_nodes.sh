#!/usr/bin/env bash
# 停止 victim 靶場節點
# 用法: bash scripts/stop_nodes.sh
set -euo pipefail
echo "=== 停止所有 victim 節點 ==="
docker exec sectest-victim bash -lc 'pkill -9 -f "python3 /work/[v]ictim" 2>/dev/null; exit 0'
sleep 2
REMAINING=$(docker exec sectest-victim bash -lc 'ps aux | grep "python3 /work/victim" | grep -v grep | wc -l')
if [[ "$REMAINING" == "0" ]]; then
    echo "✅ 所有節點已停止"
else
    echo "⚠️  仍有 $REMAINING 個節點行程"
    docker exec sectest-victim bash -lc 'ps aux | grep "python3 /work/victim" | grep -v grep'
fi
