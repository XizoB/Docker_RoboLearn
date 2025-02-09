# 使用带有CUDA和cuDNN的NVIDIA基础镜像
FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

# 设置非交互式环境防止安装提示
ENV DEBIAN_FRONTEND=noninteractive

# 使用 bash 作为默认 shell，并启用 pipefail 以严格检查管道命令的错误
SHELL ["/bin/bash", "-o", "pipefail", "-c"]


##############################################
# 基础系统配置
##############################################
RUN apt-get update && \
    # 安装 locales 本地化支持
    apt-get install -y locales && \
    # 生成UTF-8 locale
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.UTF-8

# 设置系统语言环境
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8


##############################################
# 系统工具安装
##############################################
RUN apt-get install -yq \
    # 版本控制
    git-all \
    # 虚拟显示
    xvfb \
    # 二进制修补
    patchelf \
    ### 核心系统工具 ###
    sudo \
    apt-utils \
    software-properties-common \
    ### 网络工具 ###
    wget \
    curl \
    netcat \
    openssh-server \
    iputils-ping \
    ### 开发工具链 ###
    build-essential \
    cmake \
    clang-14 \
    clang \
    llvm-14 \
    llvm-14-dev \
    llvm-14-tools \
    gcc \
    g++ \
    mold \
    ### 文本/编辑器 ###
    vim \
    nano \
    ### 压缩/解压工具 ###
    unzip \
    xz-utils \
    ### 系统监控 ###
    htop \
    ### 交互式工具 ###
    whiptail \
    dialog


##############################################
# 开发库依赖 (按功能分类)
##############################################
RUN apt-get install -yq \
    ### 基础开发库 ###
    ca-certificates \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libbz2-dev \
    liblzma-dev \
    lzma \
    libncurses5-dev \
    libgmp-dev \
    libedit-dev \
    # 系统接口
    libdb4o-cil-dev \
    libgdm-dev \
    libhidapi-dev \
    libpcap-dev \
    libtk8.6 \
    libxt-dev \
    libz-dev \
    ### 多线程/并发 ###
    libtbb-dev \
    ### Boost库 ###
    libboost-dev \
    libboost-filesystem-dev \
    libboost-test-dev \
    libboost-thread-dev \
    ### 图形相关 ###
    libgl1 \
    libglu1 \
    libglu1-mesa-dev \
    libglfw3 \
    libglew-dev \
    libegl1 \
    ### X11开发依赖 ###
    libx11-xcb-dev \
    libxcb-* \
    libxrandr-dev \
    libxinerama1 \
    libxcursor1 \
    libxi6 \
    libxrandr2 \
    '^libxcb.*-dev' \
    libx11-xcb-dev \
    libxrender-dev \
    libxi-dev \
    libxkbcommon-x11-0 \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    ### 多媒体处理 ###
    ffmpeg \
    ### Mesa驱动 ###
    mesa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libglx-mesa0 \
    libegl1-mesa \
    libgl1-mesa-dev \
    libosmesa6-dev && \
    # 清理缓存
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


##############################################
# Miniconda 配置
##############################################
RUN mkdir -p ~/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 && \
    rm ~/miniconda3/miniconda.sh

# 激活 Conda 环境 清理 Conda 缓存
RUN /bin/bash -c "source ~/miniconda3/bin/activate && \
    conda init --all && \
    pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple && \
    conda clean --all -y && \
    conda clean -a"

# 配置 Conda 清华源
RUN echo "channels:" > ~/.condarc && \
    echo "  - defaults" >> ~/.condarc && \
    echo "show_channel_urls: true" >> ~/.condarc && \
    echo "default_channels:" >> ~/.condarc && \
    echo "  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main" >> ~/.condarc && \
    echo "  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r" >> ~/.condarc && \
    echo "  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2" >> ~/.condarc && \
    echo "custom_channels:" >> ~/.condarc && \
    echo "  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud" >> ~/.condarc && \
    echo "  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud" >> ~/.condarc && \
    echo "auto_activate_base: false" >> ~/.condarc


##############################################
# MuJoCo 环境配置
##############################################
# 复制当前文件夹下的 .mujoco 文件夹到容器内的 /root/.mujoco
COPY scripts/.mujoco /root/.mujoco

# 配置 MuJoCo 200 和 MuJoCo 210 的环境变量
RUN echo -e '\n# >>> mujoco200 >>>' >> ~/.bashrc && \
    echo 'export LD_LIBRARY_PATH=~/.mujoco/mujoco200/bin${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc && \
    echo 'export MUJOCO_KEY_PATH=~/.mujoco${MUJOCO_KEY_PATH}' >> ~/.bashrc && \
    echo '# <<< mujoco200 <<<' >> ~/.bashrc && \
    echo -e '\n# >>> mujoco210 >>>' >> ~/.bashrc && \
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin' >> ~/.bashrc && \
    echo '# <<< mujoco210 <<<' >> ~/.bashrc && \
    echo -e '\n# robosuite高版本不适用' >> ~/.bashrc && \
    echo '# export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libGLEW.so' >> ~/.bashrc

# 设置容器启动时的默认命令（可选）
CMD ["bash"] 