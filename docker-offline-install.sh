#!/bin/bash
set -e

# ==================== Docker离线安装脚本 ====================
# 适用场景：内网/离线环境安装Docker及Docker Compose
# 版本：Docker 24.0.6 + Docker Compose v2.24.0
# ====================

DOCKER_VERSION="24.0.6"
COMPOSE_VERSION="v2.24.0"
COMPOSE_FILE="docker-compose-linux-x86_64"
INSTALL_DIR="/usr/local/bin"

echo "=============================================="
echo "  Docker 离线安装脚本"
echo "  Docker: ${DOCKER_VERSION}"
echo "  Docker Compose: ${COMPOSE_VERSION}"
echo "=============================================="
echo ""

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    echo "错误：请使用root权限运行此脚本"
    echo "命令：sudo $0"
    exit 1
fi

# 检查文件是否存在
if [ ! -f "docker-${DOCKER_VERSION}.tgz" ]; then
    echo "错误：未找到 docker-${DOCKER_VERSION}.tgz"
    echo "请将以下文件放入当前目录："
    echo "  1. docker-${DOCKER_VERSION}.tggz"
    echo "  2. docker-compose-linux-x86_64"
    exit 1
fi

if [ ! -f "${COMPOSE_FILE}" ]; then
    echo "错误：未找到 ${COMPOSE_FILE}"
    echo "请将docker-compose插件放入当前目录"
    exit 1
fi

# 1. 解压docker主程序
echo "[1/6] 解压Docker主程序..."
tar -xvf docker-${DOCKER_VERSION}.tgz -C ${INSTALL_DIR} --strip-components=1
rm -f docker-${DOCKER_VERSION}.tgz
echo "      ✓ Docker已安装到 ${INSTALL_DIR}"

# 2. 安装docker-compose
echo "[2/6] 安装Docker Compose..."
mv ${COMPOSE_FILE} ${INSTALL_DIR}/docker-compose
chmod +x ${INSTALL_DIR}/docker-compose
# 创建docker-compose-plugin软链接（Docker v2兼容）
ln -sf ${INSTALL_DIR}/docker-compose ${INSTALL_DIR}/docker-compose-plugin
echo "      ✓ Docker Compose已安装"

# 3. 创建systemd服务文件
echo "[3/6] 创建Docker服务..."
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
echo "      ✓ Docker服务已配置"

# 4. 重载systemd
echo "[4/6] 重载Systemd配置..."
systemctl daemon-reload
echo "      ✓ Systemd已重载"

# 5. 开机自启
echo "[5/6] 设置开机自启动..."
systemctl enable docker.service
echo "      ✓ 已设置开机自启动"

# 6. 启动Docker
echo "[6/6] 启动Docker服务..."
systemctl start docker
echo "      ✓ Docker服务已启动"

# 验证
echo ""
echo "=============================================="
echo "  安装完成！验证结果："
echo "=============================================="
echo "Docker版本:      $(docker --version)"
echo "Docker Compose:  $(docker-compose --version)"
echo "Docker服务状态:  $(systemctl is-active docker)"
echo ""
echo "常用命令："
echo "  查看状态:  systemctl status docker"
echo "  启动:      systemctl start docker"
echo "  停止:      systemctl stop docker"
echo "  重启:      systemctl restart docker"
echo "  查看版本:  docker version"
echo "=============================================="