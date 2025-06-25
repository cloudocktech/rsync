#!/command/with-contenv sh

echo "+正在运行初始化任务..."

# 创建 /conf 目录
mkdir -p /conf

echo "1.设置系统时区"
# 设置时区 https://wiki.alpinelinux.org/wiki/Setting_the_timezone
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
# 显示当前服务器时间
echo "→当前服务器时间:$(date "+%Y-%m-%d %H:%M:%S")"

echo "2.配置SSH服务"
if [ "$SSH" = "true" ]; then
    # 每次重启设置root账户随机密码
    passwd=$(tr -dc 'A-Za-z0-9!@#$%^&*()' < /dev/urandom | head -c64)
    echo "root:$passwd" | chpasswd

    # 创建.ssh目录并设置权限
    mkdir -p /conf/.ssh
    chmod 0700 /conf/.ssh
    if [ -L "/root/.ssh" ] || [ -d "/root/.ssh" ]; then
        rm -rf /root/.ssh
    fi
    ln -sf /conf/.ssh /root/.ssh

    # 生成SSH主机密钥
    ssh-keygen -A

    # 生成SSH密钥对（如果不存在）
    if [ ! -e "/conf/.ssh/id_ed25519" ]; then
        ssh-keygen -t ed25519 -a 100 -f /conf/.ssh/id_ed25519 -N "" -q -C "docker_rsync"
    fi
    chmod 0600 /conf/.ssh/id_ed25519
    chmod 0644 /conf/.ssh/id_ed25519.pub
    
    # 创建authorized_keys文件并设置权限
    if [ ! -e "/conf/.ssh/authorized_keys" ]; then
        touch /conf/.ssh/authorized_keys
    fi
    chmod 0600 /conf/.ssh/authorized_keys
    
    echo "说明："
    echo "SSH密钥位于 /conf/.ssh 目录中。"
    echo "您可以将发起同步的客户端 *.pub 文件内容复制到远程主机的 authorized_keys 文件中，以实现免密登录。"
    elif [ "$SSH" = "false" ]; then
    rm -rf /conf/.ssh
else
    echo "→SSH服务未启用。"
fi

echo "3.配置cron计划任务"
if [ "$CRON" = "true" ]; then
    # 首次运行创建crontabs文件
    mkdir -p /conf/cron
    if [ ! -e "/conf/cron/crontabs" ]; then
        touch /conf/cron/crontabs
    fi

    # 设置crontabs文件权限
    chown root:root /conf/cron/crontabs
    chmod 0600 /conf/cron/crontabs

    # 创建符号链接
    ln -sf /conf/cron/crontabs /var/spool/cron/crontabs/root
    elif [ "$CRON" = "false" ]; then
    rm -rf /conf/cron
else
    echo "→系统crontabs服务未启用。"
fi

echo "4.配置rsync"
if [ "$RSYNC" = "true" ]; then
    # 首次运行复制rsyncd.conf配置文件
    mkdir -p /conf/rsyncd
    if [ ! -e "/conf/rsyncd/rsyncd.conf" ]; then
        cp -f /rsyncd.conf.server /conf/rsyncd/rsyncd.conf
    fi
    ln -sf /conf/rsyncd/rsyncd.conf /etc/rsyncd.conf

    # 首次运行复制rsync密码文件
    if [ ! -e "/conf/rsyncd/rsync.password" ]; then
        cp -f /rsync.password /conf/rsyncd/rsync.password
    fi
    chmod 0400 /conf/rsyncd/rsync.password
    
    # 复制示例配置文件
    cp -f /rsync.password.example /conf/rsyncd/rsync.password.example
    elif [ "$RSYNC" = "false" ]; then
    rm -rf /conf/rsyncd
else
    echo "→Rsync daemon守护进程服务未启用。"
fi

echo "5.配置Lsyncd"
if [ "$LSYNCD" = "true" ]; then
    # 首次运行复制lsyncd.conf配置文件
    mkdir -p /conf/lsyncd
    if [ ! -e "/conf/lsyncd/lsyncd.conf" ]; then
        cp -f /lsyncd.conf /conf/lsyncd/lsyncd.conf
    fi

    # 复制示例配置文件
    cp -f /lsyncd.conf.example /conf/lsyncd/lsyncd.conf.example
    elif [ "$LSYNCD" = "false" ]; then
    rm -rf /conf/lsyncd
else
    echo "→Lsyncd守护进程服务未启用。"
fi
