#!/bin/bash
set -e
echo "=== Setting up VLA Drone Workspace ==="

# Update apt and install essential tools
sudo apt-get update -qq
sudo apt-get install -y \
    python3-pip python3-colcon-common-extensions \
    ros-humble-ros-gz-bridge ros-humble-ros-gz-sim \
    ros-humble-cv-bridge ros-humble-image-transport \
    xvfb x11vnc novnc net-tools wget curl git

# Install Python packages
pip3 install --quiet \
    flask requests pyngrok numpy opencv-python-headless \
    transformers accelerate bitsandbytes

# Install Micro-XRCE-DDS Agent (bridges PX4 to ROS2)
pip3 install --quiet micro-xrce-dds-agent 2>/dev/null || true
cd /tmp
git clone -b v2.4.2 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git --quiet
cd Micro-XRCE-DDS-Agent && mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -Wno-dev > /dev/null 2>&1
make -j$(nproc) > /dev/null 2>&1
sudo make install > /dev/null 2>&1
sudo ldconfig /usr/local/lib/
echo "XRCE-DDS Agent installed ✓"

# Clone PX4-Autopilot
cd /workspaces/vla-drone-ws
if [ ! -d "PX4-Autopilot" ]; then
    git clone https://github.com/PX4/PX4-Autopilot.git --recursive --quiet
    echo "PX4-Autopilot cloned ✓"
fi

# Clone paper's agent workspace
if [ ! -d "ros2-px4-agent-ws" ]; then
    git clone --recurse-submodules https://github.com/limshoonkit/ros2-px4-agent-ws.git --quiet
    echo "ros2-px4-agent-ws cloned ✓"
fi

# Install PX4 ubuntu dependencies
cd /workspaces/vla-drone-ws/PX4-Autopilot
bash ./Tools/setup/ubuntu.sh --no-nuttx --no-sim-tools 2>&1 | tail -5

# Source ROS2 in bashrc
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
echo "export ROS_DOMAIN_ID=0" >> ~/.bashrc
echo "=== Setup complete! ==="
