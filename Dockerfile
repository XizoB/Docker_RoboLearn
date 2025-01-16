# 使用基础镜像
FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

# 设置非交互式模式
ENV DEBIAN_FRONTEND=noninteractive

# 预先配置时区
RUN apt-get update && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# 安装 locales 包并生成 en_US.UTF-8 locale
RUN apt-get install -y locales && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.UTF-8

# 设置环境变量
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# 安装 whiptail、dialog 和 sudo
# whiptail 和 dialog 用于提供终端图形界面，sudo 用于提升用户权限
RUN apt-get install -y whiptail \
    dialog \
    sudo \
    wget

# 安装常用的开发工具和实用程序
# 包括构建工具、版本控制工具、网络工具、编辑器等
# build-essential \  # 包含 GCC、G++ 等编译工具
# cmake \            # 跨平台构建工具
# git-all \          # Git 版本控制工具
# software-properties-common \  # 管理软件源的工具
# netcat \           # 网络工具，用于调试网络连接
# unzip \            # 解压缩工具
# openssh-server \   # SSH 服务器
# vim \              # 文本编辑器
# iputils-ping \     # ping 工具
# openssh-server \   # SSH 服务器（重复安装，可删除）
# curl \             # 命令行工具，用于传输数据
# htop               # 交互式系统监控工具
RUN apt-get install -y \
    build-essential \
    cmake \
    git-all \
    software-properties-common \
    netcat \
    unzip \
    openssh-server \
    vim \
    iputils-ping \
    curl \
    htop

# 安装图形库和 OpenGL 相关依赖
# 这些库用于支持图形渲染和 OpenGL 应用程序
# RUN apt install -y \
#     libglfw3 \         # OpenGL 窗口和输入管理库
#     libglew-dev \      # OpenGL 扩展加载库
#     mesa-utils \       # Mesa 图形工具
#     libgl1-mesa-dri \  # Mesa DRI 驱动
#     libglx-mesa0 \     # Mesa GLX 库
#     libgl1-mesa-dev \  # Mesa OpenGL 开发库
#     xvfb \             # 虚拟帧缓冲器，用于无头环境
#     libgl1-mesa-glx \  # Mesa OpenGL 库
#     libegl1-mesa \     # Mesa EGL 库
#     libxrandr2 \       # X11 RandR 扩展库
#     libxrandr-dev \    # X11 RandR 开发库
#     libxinerama1 \     # X11 Xinerama 扩展库
#     libxcursor1 \      # X11 光标库
#     libxi6             # X11 输入扩展库
RUN apt install -y \
    libglfw3 \
    libglew-dev \
    mesa-utils \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libgl1-mesa-dev \
    xvfb \
    libgl1-mesa-glx \
    libegl1-mesa \
    libxrandr2 \
    libxrandr-dev \
    libxinerama1 \
    libxcursor1 \
    libxi6

# 安装 X11 和 OpenGL 开发依赖
# 这些库用于支持 X11 和 OpenGL 开发
# RUN apt-get install -y \
#     '^libxcb.*-dev' \  # XCB 开发库
#     libx11-xcb-dev \   # X11 XCB 开发库
#     libglu1-mesa-dev \ # Mesa GLU 开发库
#     libxrender-dev \   # X11 渲染扩展开发库
#     libxi-dev \        # X11 输入扩展开发库
#     libxkbcommon-dev \ # XKB 通用开发库
#     libxkbcommon-x11-dev \  # XKB X11 开发库
#     libosmesa6-dev \   # OSMesa 开发库
#     libglfw3 \         # OpenGL 窗口和输入管理库（重复安装，可删除）
#     patchelf \         # 修改 ELF 文件的工具
#     && rm -rf /var/lib/apt/lists/*  # 清理 apt 缓存以减小镜像大小
RUN apt-get install -y \
    '^libxcb.*-dev' \
    libx11-xcb-dev \
    libglu1-mesa-dev \
    libxrender-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libosmesa6-dev \
    patchelf \
    && rm -rf /var/lib/apt/lists/*

# 安装 Miniconda
RUN mkdir -p ~/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 && \
    rm ~/miniconda3/miniconda.sh

# 激活 Conda 环境 清理 Conda 缓存
RUN /bin/bash -c "source ~/miniconda3/bin/activate && \
    conda init --all && \
    conda config --set auto_activate_base false && \
    conda clean --all -y && \
    conda clean -a"

# 复制当前文件夹下的 .mujoco 文件夹到容器内的 /root/.mujoco
COPY scripts/.mujoco /root/.mujoco

# 配置 MuJoCo 200 和 MuJoCo 210 的环境变量
RUN echo '\n# >>> mujoco200 >>>' >> ~/.bashrc && \
    echo 'export LD_LIBRARY_PATH=~/.mujoco/mujoco200/bin${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc && \
    echo 'export MUJOCO_KEY_PATH=~/.mujoco${MUJOCO_KEY_PATH}' >> ~/.bashrc && \
    echo '# <<< mujoco200 <<<' >> ~/.bashrc && \
    echo '\n# >>> mujoco210 >>>' >> ~/.bashrc && \
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/.mujoco/mujoco210/bin' >> ~/.bashrc && \
    echo '# <<< mujoco210 <<<' >> ~/.bashrc && \
    echo '\n# robosuite高版本不适用' >> ~/.bashrc && \
    echo '# export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libGLEW.so' >> ~/.bashrc

# 设置容器启动时的默认命令（可选）
CMD ["bash"]