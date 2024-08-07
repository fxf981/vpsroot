#!/bin/bash

# 定义绿色输出的函数
green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

# 定义红色输出的函数
red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

# 检查脚本是否以root身份运行，如果不是则使用sudo
[[ $EUID -ne 0 ]] && su='sudo' || su=''

# 检查并移除passwd和shadow文件的不可变和只追加属性
if ! $su lsattr /etc/passwd /etc/shadow >/dev/null 2>&1; then
    $su chattr -i /etc/passwd /etc/shadow >/dev/null 2>&1
    $su chattr -a /etc/passwd /etc/shadow >/dev/null 2>&1
    $su lsattr /etc/passwd /etc/shadow >/dev/null 2>&1
fi

# 检查sshd_config文件中是否包含PermitRootLogin和PasswordAuthentication配置项
prl=$(grep "^#\?PermitRootLogin" /etc/ssh/sshd_config)
pa=$(grep "^#\?PasswordAuthentication" /etc/ssh/sshd_config)

if [[ -n $prl && -n $pa ]]; then
    read -p "自定义root密码: " mima
    if [[ -z "$mima" ]]; then
        red "密码不能为空" && exit 1
    fi

    echo "root:$mima" | $su chpasswd root

    $su sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    $su sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    $su service sshd restart

    green "VPS当前用户名：root"
    green "VPS当前root密码：$mima"
else
    red "当前VPS不支持root账户或无法自定义root密码" && exit 1
fi
