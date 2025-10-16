#!/bin/bash

# This script is a starting point for building and running ORB-SLAM3 on an ARM64 device.
# It uses Docker Buildx to build an ARM64 image.
# You may need to customize this script and the Dockerfile.arm64 for your specific hardware and SDKs.

# UI permissions
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth

# Only setup X11 if DISPLAY is set
if [ ! -z "$DISPLAY" ]; then
    touch $XAUTH
    if command -v xauth &> /dev/null; then
        xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
    fi
    
    if command -v xhost &> /dev/null; then
        xhost +local:docker
    else
        echo "Warning: xhost not found. Install x11-xserver-utils if you need GUI support"
    fi
else
    echo "Warning: DISPLAY not set. Running in headless mode."
fi

# Enable QEMU for multi-architecture builds
# docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Build the ARM64 Docker image
docker buildx build --platform linux/arm64 -t orbslam3:arm64 -f Dockerfile.arm64 . --load

# Remove existing container
docker rm -f orbslam3-arm64 &>/dev/null

# Create a new container
docker run -td --privileged --net=host --ipc=host \
    --name="orbslam3-arm64" \
    -e "DISPLAY=$DISPLAY" \
    -e "QT_X11_NO_MITSHM=1" \
    -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    -e "XAUTHORITY=$XAUTH" \
    -e ROS_IP=127.0.0.1 \
    --cap-add=SYS_PTRACE \
    -v `pwd`/Datasets:/Datasets \
    -v /etc/group:/etc/group:ro \
    orbslam3:arm64 bash
