# Docker 离线安装指南

## 文档信息

| 项目 | 说明 |
|------|------|
| 文档版本 | v2.0 |
| 更新日期 | 2026-04-22 |
| 适用系统 | Ubuntu 20.04 / 22.04 / 24.04 |
| Docker版本 | 24.0.6 |
| Docker Compose版本 | v2.24.0 |

---

## 目录

1. [背景说明](#背景说明)
2. [准备工作](#准备工作)
3. [下载离线包](#下载离线包)
4. [安装步骤](#安装步骤)
5. [配置镜像加速（可选）](#配置镜像加速可选)
6. [验证安装](#验证安装)
7. [卸载方法](#卸载方法)
8. [常见问题](#常见问题)

---

## 背景说明

### 适用场景

本指南适用于以下场景：
- 内网/离线环境，无法访问外网
- APT源配置损坏（如CD-ROM源失效）
- 需要快速部署Docker环境
- 生产环境需要可控的Docker版本

### 为什么选择离线安装

| 方案 | 优点 | 缺点 |
|------|------|------|
| APT在线安装 | 自动处理依赖 | 需要外网，源可能不可用 |
| Snap安装 | 简单 | 版本旧，性能差 |
| **离线包安装** | **可控、无需外网** | **需手动下载离线包** |

---

## 准备工作

### 所需文件

在有网络的电脑上下载以下文件（共3个）：

| 文件名 | 下载地址 | 说明 |
|--------|----------|------|
| docker-24.0.6.tgz | https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz | Docker主程序 |
| docker-compose-linux-x86_64 | https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 | Docker Compose插件 |
| docker-offline-install.sh | 本项目提供的安装脚本 | 自动安装 |
| docker-uninstall.sh | 本项目提供的卸载脚本 | 自动卸载 |

### 文件传输

将下载的文件通过U盘或其他方式拷贝到目标服务器的同一目录下：

```
/path/to/your/files/
├── docker-24.0.6.tgz
├── docker-compose-linux-x86_64
├── docker-offline-install.sh   ← 安装脚本
└── docker-uninstall.sh        ← 卸载脚本
```

---

## 安装步骤

### 方法一：使用脚本安装（推荐）

#### 1. 赋予执行权限

```bash
chmod +x docker-offline-install.sh
```

#### 2. 执行安装脚本

```bash
sudo ./docker-offline-install.sh
```

#### 3. 预期输出

```
==============================================
  Docker 离线安装脚本
  Docker: 24.0.6
  Docker Compose: v2.24.0
==============================================

[1/6] 解压Docker主程序...
[2/6] 安装Docker Compose...
[3/6] 创建Docker服务...
[4/6] 重载Systemd配置...
[5/6] 设置开机自启动...
[6/6] 启动Docker服务...

==============================================
  安装完成！验证结果：
==============================================
Docker版本:      Docker version 24.0.6
Docker Compose:   Docker Compose version v2.24.0
Docker服务状态:   active
==============================================
```

---

### 方法二：手动安装

如果不想使用脚本，可以手动执行以下步骤：

#### 1. 解压Docker

```bash
tar -xvf docker-24.0.6.tgz -C /usr/local/bin --strip-components=1
```

#### 2. 安装Docker Compose

```bash
# 移动文件
mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose

# 赋予执行权限
chmod +x /usr/local/bin/docker-compose

# 创建软链接（Docker v2兼容）
ln -sf /usr/local/bin/docker-compose /usr/local/bin/docker-compose-plugin
```

#### 3. 创建Systemd服务

```bash
cat > /etc/systemd/system/docker.service << 'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
```

#### 4. 启动服务

```bash
systemctl daemon-reload
systemctl enable docker.service
systemctl start docker
```

---

## 配置镜像加速（可选）

### 如果有内网镜像仓库

创建配置文件：

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": ["https://你的内网镜像地址"],
  "insecure-registries": ["内网registry IP:端口"]
}
EOF

# 重启Docker生效
sudo systemctl restart docker
```

### 常用国内镜像（仅供参考）

| 镜像源 | 地址 |
|--------|------|
| 阿里云 | https://registry.cn-hangzhou.aliyuncs.com |
| 中科大 | https://docker.mirrors.ustc.edu.cn |
| 网易 | http://hub-mirror.c.163.com |

---

## 验证安装

### 检查Docker版本

```bash
docker --version
# 输出：Docker version 24.0.6
```

### 检查Docker Compose版本

```bash
docker-compose --version
# 输出：Docker Compose version v2.24.0

# 或使用Docker内置命令
docker compose version
```

### 检查服务状态

```bash
systemctl status docker
```

### 运行测试容器

```bash
docker run hello-world
```

如果看到以下输出，说明安装成功：

```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

## 卸载方法

### 方法一：使用脚本卸载（推荐）

#### 1. 赋予执行权限

```bash
chmod +x docker-uninstall.sh
```

#### 2. 执行卸载脚本（保留数据）

```bash
sudo ./docker-uninstall.sh
```

#### 3. 如需删除所有镜像/容器/数据卷

```bash
sudo ./docker-uninstall.sh --remove-data
```

#### 4. 预期输出

```
================================================
       Docker 一键彻底卸载脚本
================================================

[1/10] 停止Docker服务...
  ✓ Docker服务已停止

[2/10] 禁用开机自启动...
  ✓ 已禁用所有自启动项

[3/10] 删除systemd服务文件...
  ✓ systemd服务文件已清理

[4/10] 删除Docker程序文件...
  ✓ Docker程序文件已删除

[5/10] 清理Docker数据...
  ○ Docker数据已保留（使用 --remove-data 可删除）

[6/10] 清理网络配置...
  ✓ 网络配置已清理

[7/10] 清理Docker用户组...
  ✓ Docker用户组已清理

[8/10] 删除配置文件...
  ✓ 配置文件已删除

[9/10] 清理环境变量...
  ✓ 环境变量已清理

[10/10] 清理残留链接...
  ✓ 残留链接已清理

================================================
       Docker 彻底卸载完成！
================================================

已清理内容：
  • Docker服务及systemd配置
  • Docker程序文件（/usr/local/bin, /usr/bin）
  • Docker Compose
  • 网络配置
  • 配置文件
  • Docker数据已保留在 /var/lib/docker

提示：如果之前使用非root用户运行docker，
      可能需要重新登录终端以清除DOCKER_HOST等环境变量
```

#### 5. 查看帮助

```bash
./docker-uninstall.sh --help
```

### 方法二：手动卸载

如果不想使用脚本，可以手动执行以下步骤：

#### 1. 停止服务

```bash
systemctl stop docker
systemctl stop docker.socket
systemctl stop containerd
systemctl disable docker.service
systemctl disable docker.socket
systemctl disable containerd.service
```

#### 2. 删除程序文件

```bash
# 删除docker主程序（离线安装位置）
rm -f /usr/local/bin/dockerd
rm -f /usr/local/bin/containerd
rm -f /usr/local/bin/containerd-shim
rm -f /usr/local/bin/containerd-shim-runc-v2
rm -f /usr/local/bin/runc
rm -f /usr/local/bin/docker-init
rm -f /usr/local/bin/docker-proxy

# 删除docker-cli
rm -f /usr/bin/dockerd
rm -f /usr/bin/docker

# 删除docker-compose
rm -f /usr/local/bin/docker-compose
rm -f /usr/local/bin/docker-compose-plugin
rm -f /usr/bin/docker-compose
```

#### 3. 删除服务文件

```bash
rm -f /etc/systemd/system/docker.service
rm -f /etc/systemd/system/docker.socket
rm -f /etc/systemd/system/containerd.service
systemctl daemon-reload
systemctl reset-failed
```

#### 4. 删除配置文件（可选）

```bash
rm -rf /etc/docker
rm -rf /etc/containerd
```

#### 5. 删除数据（可选，危险操作）

```bash
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
```

#### 6. 清理网络

```bash
ip link delete docker0 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
```

---

## 常见问题

### Q1: 提示 "cannot connect to the docker daemon"

**原因**：Docker守护进程未启动或当前用户没有docker权限

**解决方法**：
```bash
# 启动Docker
sudo systemctl start docker

# 将当前用户加入docker组
sudo usermod -aG docker $USER
# 然后重新登录
```

### Q2: 提示 "permission denied while trying to connect to the Docker daemon socket"

**原因**：没有docker组权限

**解决方法**：
```bash
sudo usermod -aG docker $USER
newgrp docker
# 或重新登录
```

### Q3: Docker服务启动失败

**排查步骤**：

```bash
# 查看详细日志
journalctl -u docker -n 50

# 检查端口占用
netstat -tlnp | grep 2375

# 手动启动查看错误
/usr/local/bin/dockerd --debug
```

### Q4: containerd未安装导致运行容器失败

**错误信息**：
```
Error starting daemon: error initializing shim: OCI runtime create failed
```

**解决方法**：下载并安装containerd单独包

```bash
# 下载containerd
wget https://github.com/containerd/containerd/releases/download/v1.7.8/containerd-1.7.8-linux-amd64.tar.gz

# 解压
tar -xvf containerd-1.7.8-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
```

### Q5: 如何升级Docker？

离线环境下需要重新下载新版本的离线包，然后：

```bash
# 停止Docker
sudo systemctl stop docker

# 重新解压（会覆盖旧版本）
sudo tar -xvf docker-新版本.tgz -C /usr/local/bin --strip-components=1

# 重启
sudo systemctl start docker
```

### Q6: 卸载后如何确认已清理干净？

```bash
# 检查docker命令
which docker
# 应该输出：which: no docker in (...)

# 检查docker服务
systemctl status docker
# 应该输出：Unit docker.service could not be found.

# 检查相关文件
ls -la /usr/local/bin/ | grep docker
# 应该无输出
```

---

## 附录

### Docker Compose离线包下载地址

| 版本 | 下载地址 |
|------|----------|
| v2.24.0（最新） | https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 |
| v2.23.0 | https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64 |
| v2.20.0 | https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64 |

### Docker各版本下载地址

| 版本 | 下载地址 |
|------|----------|
| 24.0.6（最新） | https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz |
| 23.0.6 | https://download.docker.com/linux/static/stable/x86_64/docker-23.0.6.tgz |
| 20.10.24 | https://download.docker.com/linux/static/stable/x86_64/docker-20.10.24.tgz |

### 参考链接

- Docker官方文档：https://docs.docker.com/engine/install/
- Docker Compose发布页：https://github.com/docker/compose/releases
- Docker离线包列表：https://download.docker.com/linux/static/stable/x86_64/

---

## 文件清单

| 文件名 | 说明 |
|--------|------|
| docker-24.0.6.tgz | Docker 24.0.6 离线安装包 |
| docker-compose-linux-x86_64 | Docker Compose v2.24.0 |
| docker-offline-install.sh | 一键安装脚本 |
| docker-uninstall.sh | 一键卸载脚本 |
| README.md | 本文档 |

---

*本文档最后更新于 2026-04-22*