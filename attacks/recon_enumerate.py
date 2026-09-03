#!/usr/bin/env python3
"""
測試案例 2.1：節點/主題/服務/參數枚舉（Reconnaissance）

目的：驗證未授權參與者能否完整列舉 ROS2 系統結構。
預期結果（未加固）：可列出所有節點、topic、service、參數。
成功判定：輸出中出現 victim 的節點與 /cmd_vel、/sensor_data、/set_safety_mode。

用法（attacker 容器內）：
    source /opt/ros/jazzy/setup.bash
    python3 /work/attacks/recon_enumerate.py
"""
import subprocess
import time


def warmup(settle=6):
    """暖機 ros2 daemon 並等待 unicast 探索完成（Docker bridge + unicast peers 有探索延遲）。"""
    run('ros2 daemon start')
    run('ros2 topic list')   # 觸發第一次探索
    time.sleep(settle)


def run(cmd, timeout=8):
    try:
        out = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=timeout,
            executable='/bin/bash',
        )
        return out.stdout.strip()
    except subprocess.TimeoutExpired:
        return '(timeout)'


def main():
    print('=== [2.1] ROS2 系統枚舉 ===\n')
    print('(暖機 daemon 並等待探索…)')
    warmup()
    for title, cmd in [
        ('節點 (nodes)', 'ros2 node list'),
        ('主題 (topics)', 'ros2 topic list -t'),
        ('服務 (services)', 'ros2 service list'),
    ]:
        print(f'--- {title} ---')
        print(run(f'source /opt/ros/jazzy/setup.bash && {cmd}') or '(空)')
        print()

    # 針對發現的節點列舉參數
    nodes = run('source /opt/ros/jazzy/setup.bash && ros2 node list').splitlines()
    for node in nodes:
        node = node.strip()
        if not node:
            continue
        print(f'--- 參數 of {node} ---')
        print(run(f'source /opt/ros/jazzy/setup.bash && ros2 param list {node}') or '(無)')
        print()


if __name__ == '__main__':
    main()
