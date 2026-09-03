#!/usr/bin/env python3
"""
階段 1 靶場節點：合法的 publisher / subscriber。
- publisher: 週期性發布 /cmd_vel (Twist) 與 /sensor_data (String)
- subscriber: 訂閱 /cmd_vel，印出實際「被執行」的指令

作為攻擊測試的對照基準：正常情況下 /cmd_vel 只有本節點發布的合法值。

用法（在 victim 容器內）：
    source /opt/ros/jazzy/setup.bash
    python3 /work/victim/talker_listener.py
"""
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from std_msgs.msg import String


class VictimTalkerListener(Node):
    def __init__(self):
        super().__init__('victim_talker_listener')
        # 合法控制指令發布者
        self.cmd_pub = self.create_publisher(Twist, '/cmd_vel', 10)
        # 敏感感測資料發布者
        self.sensor_pub = self.create_publisher(String, '/sensor_data', 10)
        # 訂閱自己的 /cmd_vel，模擬「致動器」實際執行的指令
        self.create_subscription(Twist, '/cmd_vel', self.on_cmd, 10)

        self.timer = self.create_timer(1.0, self.tick)
        self.seq = 0
        self.get_logger().info('victim talker/listener 啟動：合法巡航中')

    def tick(self):
        self.seq += 1
        # 合法巡航指令：固定緩慢前進
        cmd = Twist()
        cmd.linear.x = 0.2
        cmd.angular.z = 0.0
        self.cmd_pub.publish(cmd)

        sensor = String()
        sensor.data = f'battery=87%,gps=25.033,121.565,seq={self.seq}'
        self.sensor_pub.publish(sensor)

    def on_cmd(self, msg: Twist):
        # 致動器：這是「機器人實際會做的動作」
        self.get_logger().info(
            f'[ACTUATOR] 執行 linear.x={msg.linear.x:.2f} angular.z={msg.angular.z:.2f}'
        )


def main():
    rclpy.init()
    node = VictimTalkerListener()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
