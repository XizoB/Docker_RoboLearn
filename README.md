# 文件作用

```
- scripts/.mujoco: mujoco文件夹，用于制作镜像的时候，将其COPY进镜像
- Dockerfile：制作镜像
- robolearn_22.sh: 运行镜像 docker run
- touch_xauth_robolearn_22.sh: 每次重启电脑的时候xauth_docker_robolearn_22会变为文件夹，需要将/tmp/xauth_docker_robolearn_22变成文件
```

# 运行步骤
## 为了保证docker制作成功，最好先在本地下载好基础镜像
```
docker pull nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04
```

## 给bash文件添加可执行权限

```
sudo chmod +x ./robolearn_22.bash
sudo chmod +x ./touch_xauth_robolearn_22.sh
```

## 制作镜像

- 其中参数-t后xizobu/robolearn_22:base是制作后，将制作的镜像自定义的名字

```
docker build -t xizobu/robolearn_22:base .
```

- 其中参数--progress=plain表示详细显示build细节，参数> build.log 2>&1把日志保存入build.log 中
```
docker build --progress=plain -t xizobu/robolearn_22:base . > build.log 2>&1
```

## 运行镜像

- 其中参数base是镜像的tag

```
./robolearn_20.bash base
```

## 重启电脑后需要执行

```
./touch_xauth_robolearn_22.sh
```

