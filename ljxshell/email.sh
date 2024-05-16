#!/bin/bash


project_name=$1
if [ -z "$project_name" ]; then
    echo "使用错误，使用方法 sh mail.sh 项目名"
    exit 1
fi

# 定义接收者列表
recipients=("18742423211@139.com" "1553232697@qq.com" "18640549232@163.com")

# 定义要发送的配置文件列表
config_files=("/root/.kube/config" "/root/.talos/config")
#config_files=("/home/ljx/nginx.conf" "/home/ljx/nginx.conf")

# 安装msmtp和mailx
install_deps() {
    if command -v yum &> /dev/null; then
        echo "正在为CentOS/RHEL系统安装必要软件..."
        sudo yum install -y msmtp ca-certificates mailx
    else
        echo "无法识别的包管理器，请手动安装msmtp和mailx。"
        exit 1
    fi
}

# 新增函数：修改邮件配置文件，避免重复添加
update_mail_rc() {
    local config_items=(
        "# 邮箱"
        "set from=18742423211@163.com"
        "# 使用SMTP发送邮件，需在邮箱设置中允许SMTP发送"
        "set smtp=smtp.163.com"
        "# 邮箱用户名"
        "set smtp-auth-user=18742423211@163.com"
        "# 邮箱授权码"
        "set smtp-auth-password=CCEARMNBAJVJHAKQ"
        "set smtp-auth=login"
    )

    # 检查文件是否存在
    if [ ! -f /etc/mail.rc ]; then
        echo "/etc/mail.rc 文件不存在，无法修改。"
        return 1
    fi

    # 遍历配置项，检查是否已存在，若不存在则追加
    for item in "${config_items[@]}"; do
        if ! grep -q "$item" /etc/mail.rc; then
            echo "$item" >> /etc/mail.rc
        fi
    done

    # 所有配置项检查完毕，确认是否全部存在
    local all_exist=true
    for item in "${config_items[@]}"; do
        if ! grep -q "$item" /etc/mail.rc; then
            all_exist=false
            break
        fi
    done

    if [ "$all_exist" = true ]; then
        echo "/etc/mail.rc 配置已存在或已成功更新。"
    else
        echo "更新 /etc/mail.rc 配置时发生错误，部分配置未成功添加。"
    fi
}

# 调用新增的函数以修改配置文件
update_mail_rc


# 配置msmtp
configure_msmtp() {
    if [ ! -f ~/.msmtprc ]; then
        {
            echo "account default"
            echo "host smtp.139.com"
            echo "port 465"
            echo "auth on"
            echo "tls on"
            echo "tls_starttls off"
            echo "tls_trust_file /etc/ssl/certs/ca-certificates.crt"
            echo "from 18742423211@139.com"
            echo "user 18742423211@139.com"
            echo "password 35e4a8d7063baae34a00"
        } >~/.msmtprc
        chmod 600 ~/.msmtprc
    fi
}

# 修改后的发送邮件函数，增加自定义邮件正文内容参数
send_email_with_attachment() {
    local config_file=$1
    local subject=$2
    local body=$3
    local recipients=("${@:4}")

    if [ -f "$config_file" ]; then
        echo "正在发送${config_file##*/}到以下邮箱：${recipients[*]}，邮件主题为：$subject..."

        # 使用echo生成邮件正文内容并结合附件发送
        {
            echo -e "$body\n\n邮件包含附件: ${config_file##*/}"
        } | mailx -s "$subject" \
                 -S smtp=smtps://smtp.139.com:465 \
                 -S smtp-auth=login \
                 -S ssl-verify=ignore \
                 -S from="18742423211@139.com" \
                 -a "$config_file" \
                 "${recipients[@]}"

        if [ $? -eq 0 ]; then
            echo "${config_file##*/}邮件（主题：$subject）成功发送至所有接收者。"
        else
            echo "${config_file##*/}邮件（主题：$subject）发送失败，请检查配置后重试。"
        fi
    else
        echo "${config_file##*/}文件不存在，跳过发送。"
    fi
}

# 从控制台动态获取邮箱地址
echo "请输入额外的收件人邮箱地址: 如果不需要额外发送其他邮箱，请直接回车"
read additional_recipient

# 将用户输入的邮箱地址添加到收件人列表
if [[ -n $additional_recipient ]]; then
    recipients+=("$additional_recipient")
fi
# 主程序
install_deps
#configure_msmtp

# 定义自定义邮件正文内容
k8s_body="这是Kubernetes配置文件... 项目名为：$project_name"
talos_body="这是Talos系统配置文件... 项目名为：$project_name"

#k8s_re_body=${k8s_body}${project_name}
#talos_re_body=${talos_body}${project_name}

# 遍历配置文件列表并发送邮件，同时附带自定义邮件正文
for config_file in "${config_files[@]}"; do
    case "$config_file" in
        "/root/.kube/config")
            send_email_with_attachment "$config_file" "Kubernetes Config 文件 项目名为：$project_name" "$k8s_body" "${recipients[@]}"
            ;;
        "/root/.talos/config")
            send_email_with_attachment "$config_file" "Talos System Config 文件 项目名为：$project_name" "$talos_body" "${recipients[@]}"
            ;;
        *)
            echo "未知的配置文件：$config_file，跳过发送。"
            ;;
    esac
done

