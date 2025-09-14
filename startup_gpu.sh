#!/bin/bash
set -xe

# --- 기본 업데이트 & 필수 툴 ---
apt-get update
apt-get install -y linux-headers-$(uname -r) ubuntu-drivers-common ca-certificates curl gnupg lsb-release apt-transport-https git

# --- 권장 NVIDIA 드라이버 자동 설치 (권장; 필요하면 재부팅 후 확인) ---
ubuntu-drivers autoinstall || true

# --- Docker 설치 (간단 스크립트 사용) ---
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
# $SUDO_USER 가 비어있을 수 있으므로 조심
if [ -n "$SUDO_USER" ]; then
  usermod -aG docker $SUDO_USER || true
fi

# --- NVIDIA container toolkit 설치 ---
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/${distribution}/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
apt-get install -y nvidia-container-toolkit
# 재시작(없어도 동작하는 경우 있지만 안전하게)
systemctl restart docker || true

# --- 작업 디렉터리 준비 ---
WORKDIR="/home/${SUDO_USER:-ubuntu}/workspace"
mkdir -p "${WORKDIR}"
chown ${SUDO_USER:-0}:${SUDO_USER:-0} "${WORKDIR}" || true

# --- (선택) Git 레포 자동 클론 ---
# 환경변수 GIT_REPO_URL 로 전달하면 자동으로 클론
if [ -n "${GIT_REPO_URL}" ]; then
  su - ${SUDO_USER:-$USER} -c "git clone ${GIT_REPO_URL} ${WORKDIR}/repo || true"
fi

# --- 도커 이미지 정보 (metadata 로 DOCKER_IMAGE 로 전달 가능) ---
DOCKER_IMAGE="${DOCKER_IMAGE:-giniyong/transbase-env:torch2.8-cu126}"

# 시도: 이미지 pull (에러여도 계속)
docker pull "${DOCKER_IMAGE}" || true

# --- 컨테이너 실행 (Jupyter Lab) ---
# 마운트할 디렉터리 지정. repo가 있으면 그것을, 아니면 workspace 전체 마운트
MOUNT_SRC="${WORKDIR}/repo"
if [ ! -d "${MOUNT_SRC}" ]; then
  MOUNT_SRC="${WORKDIR}"
fi

docker run -d --rm --gpus all \
  --name trans-jup \
  -v "${MOUNT_SRC}:/workspace" \
  -p 127.0.0.1:8888:8888 \
  -e WANDB_MODE=offline \
  -u "$(id -u ${SUDO_USER:-$USER}):$(id -g ${SUDO_USER:-$USER})" \
  "${DOCKER_IMAGE}" \
  bash -c "cd /workspace && jupyter lab --no-browser --ip=127.0.0.1 --port=8888" || true

# 끝
