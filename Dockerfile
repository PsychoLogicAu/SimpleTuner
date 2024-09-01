# Stage 1: Base Image Setup
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS base

# /workspace is the default volume for Runpod & other hosts
WORKDIR /workspace

# Update apt-get
RUN apt-get update -y

# Prevents different commands from being stuck by waiting on user input during build
ENV DEBIAN_FRONTEND noninteractive

# Install misc unix libraries
RUN apt-get install -y --no-install-recommends openssh-server \
                                               openssh-client \
                                               git \
                                               git-lfs \
                                               wget \
                                               curl \
                                               tmux \
                                               tldr \
                                               nvtop \
                                               vim \
                                               rsync \
                                               net-tools \
                                               less \
                                               iputils-ping \
                                               7zip \
                                               zip \
                                               unzip \
                                               htop \
                                               inotify-tools \
                                               libgl1-mesa-glx \
                                               libglib2.0-0 \
                                               libaio-dev

# Set up git to support LFS, and to store credentials; useful for Huggingface Hub
RUN git config --global credential.helper store && \
    git lfs install

# Install Python VENV
RUN apt-get install -y python3.10-venv

# Ensure SSH access. Not needed for Runpod but is required on Vast and other Docker hosts
EXPOSE 22/tcp

# Python
RUN apt-get update -y && apt-get install -y python3 python3-pip
RUN python3 -m pip install pip --upgrade

# Stage 2: Dependency Installation and Application Setup
FROM base AS final

# HF
ENV HF_HOME=/workspace/huggingface

RUN pip3 install "huggingface_hub[cli]"

# WanDB
RUN pip3 install wandb

# Clone SimpleTuner
# RUN git clone https://github.com/bghira/SimpleTuner --branch release
# RUN git clone https://github.com/bghira/SimpleTuner --branch main # Uncomment to use latest (possibly unstable) version
RUN git clone https://github.com/PsychoLogicAu/SimpleTuner --branch feature/docker-compose-main


# Install SimpleTuner
RUN pip3 install poetry
RUN cd SimpleTuner && python3 -m venv .venv && poetry install --no-root
RUN chmod +x SimpleTuner/train.sh

# Copy start script with exec permissions
COPY --chmod=755 local-start.sh /start.sh

RUN echo "source SimpleTuner/.venv/bin/activate" > activate.sh && chmod +x activate.sh

# Set entrypoint to activate the virtual environment and start an interactive shell
# ENTRYPOINT ["/bin/bash", "-c", "source /workspace/SimpleTuner/.venv/bin/activate && exec /bin/bash"]

# Dummy entrypoint
ENTRYPOINT [ "/start.sh" ]
