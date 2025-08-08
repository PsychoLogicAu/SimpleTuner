# Stage 1: Base Image Setup
FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu22.04 AS base

ARG PYTHON_VERSION=3.11

# Prevent commands from blocking for input during build
ENV DEBIAN_FRONTEND=noninteractive

# /workspace is the default volume for Runpod & other hosts
WORKDIR /workspace

# libglib2.0-0 

# Base system dependencies (including Python ${PYTHON_VERSION} toolchain)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        git-lfs \
        htop \
        inotify-tools \
        iputils-ping \
        less \
        libgl1-mesa-glx \
        libsm6 \
        libxext6 \
        libopenmpi-dev \
        net-tools \
        nvtop \
        openmpi-bin \
        openssh-client \
        openssh-server \
        p7zip-full \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-venv \
        rsync \
        tmux \
        tldr \
        unzip \
        vim \
        wget \
        zip && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: Dependency Installation and Application Setup
FROM base AS final

# Configure git to support LFS and credential storage
RUN git config --global credential.helper store && \
    git lfs install

# Create a dedicated virtual environment with the requested Python version
RUN python${PYTHON_VERSION} -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel

# Use the virtual environment for all subsequent Python work
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

# Ensure SSH access. Not needed for Runpod but is required on Vast and other Docker hosts
EXPOSE 22/tcp

# Clone SimpleTuner
# RUN git clone https://github.com/bghira/SimpleTuner --branch release
# RUN git clone https://github.com/bghira/SimpleTuner --branch main # Uncomment to use latest (possibly unstable) version
ARG CACHEBUST=1
RUN git clone https://github.com/PsychoLogicAu/SimpleTuner --branch feature/v2.1.3+docker-compose

# HuggingFace cache location and platform hint for setup.py
ARG HF_HOME=/workspace/huggingface
ENV HF_HOME=${HF_HOME}
ENV SIMPLETUNER_PLATFORM=cuda

# Install supporting CLIs ahead of the project install
RUN pip install --no-cache-dir "huggingface_hub[cli]" wandb

# Install MPI bindings needed for CUDA multi-node support
RUN pip install --no-cache-dir mpi4py

# Install SimpleTuner from PyPI to match published releases
RUN pip install --no-cache-dir simpletuner

# Copy start script with exec permissions
COPY --chmod=755 local-start.sh /start.sh

# Ensure we remain in the default workspace location
WORKDIR /workspace

RUN echo "source SimpleTuner/.venv/bin/activate && export HF_HOME='/data/cache/huggingface'" > activate.sh && chmod +x activate.sh

#ENV PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
ENV PYTORCH_CUDA_ALLOC_CONF="garbage_collection_threshold:0.8,max_split_size_mb:128"

# Dummy entrypoint
# ENTRYPOINT [ "/start.sh" ]

# Set entrypoint to activate the virtual environment and start an interactive shell
ENTRYPOINT ["/bin/bash", "-c", "source SimpleTuner/.venv/bin/activate && /bin/bash -c 'SimpleTuner/train.sh'"]
