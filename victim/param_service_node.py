#!/usr/bin/env python3
"""
階段 1 靶場節點：帶 parameter 與 service 的節點。
- parameter: max_speed（敏感設定，攻擊測試 2.5 會嘗試竄改）
- service: /set_safety_mode (std_srvs/SetBool) 切換安全模式

作為攻擊測試的對照基準。

用法（在 victim 容器內）：
    source /opt/ros/jazzy/setup.bash
    python3 /work/victim/param_service_node.py
"""
import rclpy
from rclpy.node import Node
from rcl_interfaces.msg import ParameterDescriptor
from std_srvs.srv import SetBool


class VictimParamService(Node):
    def __init__(self):
        super().__init__('victim_param_service')
        # 敏感參數：最高速度限制
        self.declare_parameter(
            'max_speed', 1.0,
            ParameterDescriptor(description='致動器最高速度上限 (m/s)')
        )
        self.safety_mode = True
        self.srv = self.create_service(SetBool, '/set_safety_mode', self.on_set_safety)

        self.add_on_set_parameters_callback(self.on_param_change)
        self.timer = self.create_timer(2.0, self.report)
        self.get_logger().info('victim param/service 啟動')

    def on_param_change(self, params):
        from rcl_interfaces.msg import SetParametersResult
        for p in params:
            self.get_logger().warn(f'[PARAM] {p.name} 被設定為 {p.value}')
        return SetParametersResult(successful=True)

    def on_set_safety(self, request, response):
        self.safety_mode = request.data
        self.get_logger().warn(f'[SERVICE] safety_mode 被設為 {request.data}')
        response.success = True
        response.message = f'safety_mode={self.safety_mode}'
        return response

    def report(self):
        max_speed = self.get_parameter('max_speed').value
        self.get_logger().info(
            f'目前狀態: max_speed={max_speed} safety_mode={self.safety_mode}'
        )


def main():
    rclpy.init()
    node = VictimParamService()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
