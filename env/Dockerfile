FROM ros:jazzy-ros-base

# 測試/攻擊/監控工具
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-pip \
        python3-scapy \
        tcpdump \
        tshark \
        iproute2 \
        iputils-ping \
        iptables \
        net-tools \
        git \
        ros-jazzy-demo-nodes-py \
        ros-jazzy-demo-nodes-cpp \
        ros-jazzy-sros2 \
        ros-jazzy-sros2-cmake \
    && rm -rf /var/lib/apt/lists/*

# aztarna（ROS/ROS2 掃描器）— 以 pip 安裝，容許失敗不阻斷建置
RUN pip3 install --no-cache-dir --break-system-packages aztarna || true

# 掛載點：專案根目錄會 bind-mount 到 /work
WORKDIR /work

# 讓每個 shell 自動 source ROS2
RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc

CMD ["bash"]
