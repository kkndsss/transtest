# Dockerfile (권장: PyTorch + CUDA 12.6 베이스)
FROM pytorch/pytorch:2.8.0-cuda12.6-cudnn9-runtime

WORKDIR /workspace
ENV PYTHONUNBUFFERED=1

# requirements만 복사 (코드/데이터는 빌드 컨텍스트에서 제외하도록 .dockerignore 사용)
COPY requirements.txt /workspace/requirements.txt

# pip 업그레이드 + 패키지 설치 (torch는 베이스 이미지에 이미 포함되어 있으므로 requirements에서 삭제되어 있어야 함)
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r /workspace/requirements.txt

# 컨테이너 실행 시 기본으로 bash 를 띄움. 실행 때 명령을 override(예: jupyter lab 실행) 할 것
CMD ["bash"]
