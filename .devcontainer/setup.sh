#!/bin/bash
# =============================================================
# VLA Drone Workspace Setup Script
# Tested: Ubuntu 22.04, ROS2 Humble, Gazebo Harmonic, April 2025
# =============================================================
set -e  # stop on any error

log() { echo ""; echo "===> $1"; echo ""; }

log "STEP 1/7: System packages"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    curl wget git build-essential cmake python3-pip \
    lsb-release gnupg software-properties-common \
    net-tools iputils-ping \
    mesa-utils libgl1-mesa-glx libgles2-mesa-dev \
    libegl1-mesa-dev libgbm-dev \
    python3-colcon-common-extensions python3-vcstool \
    2>&1 | tail -3

log "STEP 2/7: Installing ROS2 Humble"
# Add ROS2 apt key and source
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    ros-humble-desktop \
    ros-humble-ros-gz-bridge \
    ros-humble-ros-gz-sim \
    ros-humble-cv-bridge \
    ros-humble-image-transport \
    ros-humble-vision-msgs \
    ros-dev-tools \
    2>&1 | tail -3
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
echo "export ROS_DOMAIN_ID=0" >> ~/.bashrc
log "ROS2 Humble installed ✓"

log "STEP 3/7: Installing Gazebo Harmonic"
sudo curl -sSL https://packages.osrfoundation.org/gazebo.gpg \
    -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
    http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y gz-harmonic 2>&1 | tail -3
log "Gazebo Harmonic installed ✓"

log "STEP 4/7: Installing Micro-XRCE-DDS Agent"
cd /tmp
git clone -b v2.4.2 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git --quiet
cd Micro-XRCE-DDS-Agent
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -Wno-dev -DCMAKE_INSTALL_PREFIX=/usr/local > /dev/null 2>&1
make -j$(nproc) 2>&1 | tail -2
sudo make install 2>&1 | tail -2
sudo ldconfig
log "Micro-XRCE-DDS Agent v2.4.2 installed ✓"

log "STEP 5/7: Cloning PX4-Autopilot"
cd /workspaces/vla-drone-ws
if [ ! -d "PX4-Autopilot" ]; then
    git clone https://github.com/PX4/PX4-Autopilot.git --recursive --depth=1 --quiet
fi
cd PX4-Autopilot
# Install PX4 dependencies (Ubuntu script, no NuttX for simulation only)
bash ./Tools/setup/ubuntu.sh --no-nuttx 2>&1 | tail -5
log "PX4-Autopilot cloned ✓"

log "STEP 6/7: Cloning paper's ROS2 agent workspace"
cd /workspaces/vla-drone-ws
if [ ! -d "ros2-px4-agent-ws" ]; then
    git clone --recurse-submodules \
        https://github.com/limshoonkit/ros2-px4-agent-ws.git --quiet
fi
# Build px4_msgs (needed for ROS2 ↔ PX4 message types)
cd ros2-px4-agent-ws
source /opt/ros/humble/setup.bash
colcon build --packages-select px4_msgs 2>&1 | tail -3
log "Paper repo built ✓"

log "STEP 7/7: Python packages for VLA"
pip3 install --quiet --no-warn-script-location \
    flask requests pyngrok numpy \
    opencv-python-headless pillow
log "Python packages installed ✓"

log "================================================"
log "ALL DONE! Your workspace is ready."
log "Next: Open the 'Gazebo Visual Desktop' port tab"
log "================================================"
