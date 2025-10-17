# ORB_SLAM3 Docker

This Docker setup provides a containerized environment for running ORB-SLAM3, optimized for various platforms including ARM64 (e.g., Qualcomm QCS8550). It is based on ROS Noetic Ubuntu 20.04.

## Supported Versions

- **CPU-based**: For systems without NVIDIA GPUs or ARM64 devices.
- **CUDA-based**: For NVIDIA GPU-accelerated systems (requires NVIDIA Docker support).

Check your GPU setup with `nvidia-smi`. If it works, use the CUDA version; otherwise, use CPU.

## Prerequisites

- Docker installed on your system.
- For CUDA version: [NVIDIA Docker Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).
- For display output (optional): X11 forwarding if running remotely (e.g., via SSH).
  - On your local machine: Ensure X server is running.
  - On remote machine: Set `DISPLAY` and mount `/tmp/.X11-unix`.
- Git for cloning repositories.

## Building the Docker Image

1. Clone or navigate to this repository:
   ```bash
   cd /path/to/orbslam3_docker
   ```

2. Build the appropriate image:
   - For CPU/ARM64:
     ```bash
     ./build_container_cpu.sh
     ```
   - For CUDA (NVIDIA):
     ```bash
     ./build_container_cuda.sh
     ```
   - Or manually:
     ```bash
     docker build -f Dockerfile.cpu -t orbslam3:cpu .
     # or
     docker build -f Dockerfile.cuda -t orbslam3:cuda .
     # For ARM64:
     docker build -f Dockerfile.arm64 -t orbslam3:arm64 .
     ```

   The build process compiles ORB-SLAM3 with optimizations (e.g., ARM NEON for ARM64).

## Preparing Datasets

1. Download sample datasets (e.g., EuRoC):
   ```bash
   ./download_dataset_sample.sh
   ```
   This downloads MH01 from EuRoC into `Datasets/EuRoC/MH01/`.

2. For additional sequences, manually download and place in `Datasets/EuRoC/`:
   ```bash
   mkdir -p Datasets/EuRoC/MH02
   wget -O Datasets/EuRoC/MH_02_easy.zip http://robotics.ethz.ch/~asl-datasets/ijrr_euroc_mav_dataset/machine_hall/MH_02_easy/MH_02_easy.zip
   unzip Datasets/EuRoC/MH_02_easy.zip -d Datasets/EuRoC/MH02
   ```

## Running ORB-SLAM3

### Basic Run (No Display)

Run the container and execute SLAM:
```bash
# For CPU/ARM64
docker run -it --rm -v $(pwd)/Datasets:/app/Datasets:ro orbslam3:arm64 bash -c "
cd ORB_SLAM3 &&
./Examples/Monocular/mono_euroc Vocabulary/ORBvoc.txt Examples/Monocular/EuRoC.yaml /app/Datasets/EuRoC/MH01/ Examples/Monocular/EuRoC_TimeStamps/MH01.txt
"
```

### With Display Output (For Visualization)

If you have X11 access (local or forwarded):

1. Set DISPLAY:
   ```bash
   export DISPLAY=your_local_ip:0.0  # e.g., 100.98.51.50:0.0 for SSH tunnel
   ```

2. Run with display:
   ```bash
   docker run -it --rm \
     --env="DISPLAY=$DISPLAY" \
     --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
     --volume="$(pwd)/Datasets:/app/Datasets:ro" \
     --volume="$(pwd)/qualcomm:/app/results" \
     orbslam3:arm64 bash -c "
   cd ORB_SLAM3 &&
   ./Examples/Monocular/mono_euroc Vocabulary/ORBvoc.txt Examples/Monocular/EuRoC.yaml /app/Datasets/EuRoC/MH01/ Examples/Monocular/EuRoC_TimeStamps/MH01.txt
   "
   ```

   - Results (trajectory, logs) will be saved in the mounted `qualcomm` folder.

### Inertial SLAM (With IMU)

For datasets with IMU (e.g., EuRoC):
```bash
docker run -it --rm \
  --env="DISPLAY=$DISPLAY" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume="$(pwd)/Datasets:/app/Datasets:ro" \
  orbslam3:arm64 bash -c "
cd ORB_SLAM3 &&
./Examples/Monocular-Inertial/mono_inertial_euroc Vocabulary/ORBvoc.txt Examples/Monocular-Inertial/EuRoC.yaml /app/Datasets/EuRoC/MH01/ Examples/Monocular-Inertial/EuRoC_TimeStamps/MH01.txt
"
```

### Interactive Shell

For development or manual runs:
```bash
docker run -it --rm \
  --env="DISPLAY=$DISPLAY" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume="$(pwd)/Datasets:/app/Datasets:ro" \
  --volume="$(pwd)/qualcomm:/app/results" \
  orbslam3:arm64 bash
```

Inside the container:
- Build if needed: `cd ORB_SLAM3 && ./build.sh`
- Run examples: `./Examples/Monocular/mono_euroc ...`
- Edit code: Use VS Code remote or your preferred editor.

## Benchmarking

For performance benchmarking on mobile platforms (e.g., QCS8550):
- Use the provided `benchmark_slam_qcs8550.sh` script.
- It logs CPU, memory, thermal, and trajectory metrics.
- Run: `./benchmark_slam_qcs8550.sh`

## Troubleshooting

- **Display Issues**: Ensure X11 is forwarded correctly. On remote machines, allow connections with `xhost +local:host` or specific IP.
- **Build Failures**: Check Docker logs. Ensure sufficient RAM (4GB+ recommended).
- **Dataset Errors**: Verify paths and timestamps match image counts.
- **ARM64 Specific**: Use `orbslam3:arm64` for Qualcomm devices; NEON optimizations are enabled.

## Contributing

Use VS Code remote development for code changes. Commit builds and test on multiple platforms.

For issues, check the [ORB-SLAM3 repository](https://github.com/UZ-SLAMLab/ORB_SLAM3).
