#!/bin/bash
# 参数检查
talosctl_version="talosctl version"
talosctl_service="talosctl service"
command_jiqun="talosctl kubeconfig"
kubectl_version="kubectl get pods -A"
#生成配置文件
command_token="talosctl  gen  config  mingyang https://172.16.102.102:6443  --config-patch-control-plane @patch.yaml --config-patch-worker @patch-worker.yaml"
all_file_name=*
patch_name=patch*
k8s_path=/home/k8s
failpath=/opt
jituan_path=$1
talos_path=$2
cncp_path=$3
ipv4_patch=$4
ipv6_path=$5
linshi_ip=$6
del_jt=${failpath}/${jituan_path}
ctrl_file=${failpath}/${jituan_path}/${talos_path}/controlplane.yaml
taloscfg_file=${failpath}/${jituan_path}/${talos_path}/talosconfig
talos_file_path=${failpath}/${jituan_path}/${talos_path}





# 检查参数个数是否满足要求
if [[ $# -lt 6 ]]; then
    echo "使用错误！使用方法 sh danji.sh 集团名 talos cncp-helm 要修改的IPV4 + 要修改的IPV6地址   + 临时IP地址绑定的地址!"
    echo "示例： sh danji.sh beitou talos cncp-helm 172.16.102.145 2408:8631:c02:ffa2::145 172.16.102.220"
    exit 1
fi

# 逐个检查参数是否合法（以检查非空且非仅空格字符为例）
for ((i=1; i<=6; i++)); do
    param="${!i}"
    if [[ -z "$param" || "$param" =~ ^\s+$ ]]; then
        echo "使用错误！使用方法 sh danji.sh 集团名 talos cncp-helm 要修改的IPV4 + 要修改的IPV6地址  + 临时IP地址绑定的地址!"
        echo "示例： sh danji.sh beitou talos cncp-helm 172.16.102.145 2408:8631:c02:ffa2::145 172.16.102.220"
        exit 1
    fi
done

# 所有参数检查通过，记录日志并继续执行

kubecfg_path="/root/.kube/config"
if rm "$kubecfg_path"; then
  echo "文件 '$kubecfg_path' 已成功删除。"
else
  echo "删除文件 '$kubecfg_path' 不存在。"
fi

talos_tlcfg_path="/root/.talos/config"
if rm "$talos_tlcfg_path"; then
  echo "文件 '$talos_tlcfg_path' 已成功删除。"
else
  echo "删除文件 '$talos_tlcfg_path' 不存在。"
fi

#集团
if [ -n "$1" ];then
    echo "开始创建"{$1}"文件夹" 
    jituan_file=`mkdir -p ${failpath}/${jituan_path}`
    echo "创建集团文件夹成功 集团文件夹名称为：${jituan_path}"
    else
    echo "创建集团文件夹异常"
    exit 1
fi

#创建talos
if [ -n "$2" ];then
    echo "开始创建"${2}"文件夹" 
    talos_file=`mkdir -p ${failpath}/${jituan_path}/${talos_path}`
    echo "创建talos文件夹成功 talos文件夹名称为：${talos_path}" 
    else
    echo "创建talos失败"
    rm -rf ${del_jt}
    exit 1
fi

#创建cncp
if [ -n "$3" ];then
    echo "开始创建"${3}"文件夹 " 
    cncphelm_file=`mkdir -p ${failpath}/${jituan_path}/${cncp_path}`
    k8s_file=`mkdir -p ${k8s_path}`
    echo "创建cncp-helm文件夹成功 cncp-helm文件夹名称为：${cncp_path}" 
    else
    echo "创建失败"
    rm -rf ${del_jt}
    exit 1
fi

#复制步骤
if [ -a "$k8s_path" ];then
    echo "开始复制patch文件"
    patch_cp=`cp -f ${k8s_path}/${patch_name} ${failpath}/${jituan_path}/${talos_path}`
    all_cp=`cp -r -f ${k8s_path}/${all_file_name} ${failpath}/${jituan_path}/${cncp_path}`
    echo "复制成功 复制路径为${del_jt}"
    else
    echo "复制失败"
    exit 1
fi

cd ${talos_file_path}




#生成配置文件
while true; do
  # 执行命令并捕获其输出和退出状态
  output=$(eval "$command_token" 2>&1)
  exit_code=$?

  # 检查命令输出是否包含 "error"
  if [[ $output == *"error"* ]]; then
    echo "配置文件生成异常"
    exit 1
  else
    echo "配置文件生成成功"
    # 输出不包含 "error"，则认为命令执行成功，跳出循环
    break
  fi
done




#文件校验
if [ -a "$ctrl_file" ];then
    echo "检查配置文件成功 $ctrl_file"
    else
    echo "检查文件失败，请查看配置文件"
    exit 1
fi

if [ -n "$4" ];then
    echo "开始修改controlplane.yaml文件"
    sed -i "s/172.16.102.102/${ipv4_patch}/g" "${ctrl_file}"
    sed -i "s/2408:8631:c02:ffa2::102/${ipv6_path}/g" "${ctrl_file}"
    #echo "修改成功" `cat ${ctrl_file} 
    else
    echo "修改IP地址失败"
    exit 1
fi

#关联集群IP
if [ -n "$5" ];then
    echo "开始下发配置文件"
    xiafa=$(talosctl apply-config --insecure -n ${linshi_ip} --file controlplane.yaml)
    echo "下发成功：$xiafa "
    else
    echo "配置文件下发异常"
    exit 1
fi



#talosmerge，客户端IP集群绑定
if [ -n "$6" ];then
    echo "开始修改talosconfig.yaml文件"
    sed -i "s/127.0.0.1/${ipv4_patch}/g" "${taloscfg_file}"
    sed -i "5a\        nodes:" "${taloscfg_file}"
    sed -i "6a\            - ${ipv4_patch}" "${taloscfg_file}"
    #echo "修改成功" `cat ${taloscfg_file} 
    else
    echo "修改talos地址失败"
    exit 1
fi


#合并配置文件
talosctl config merge ./talosconfig
  if [[ $? -ne 0 ]]; then
      echo "合并talosconfig失败"
      exit 1
  else
      echo "合并talosconfig成功"
  fi


while true; do
  # 执行命令并捕获其输出和退出状态
  output=$(eval "$talosctl_version" 2>&1)
  exit_code=$?
  # 检查命令输出是否包含 "error"
  if [[ $output == *"error"* ]]; then
    echo "访问talos版本中，请等待2分钟，不要进行任何操作"
    sleep 200
    #talosctl bootstrap
  else
    echo "talos访问成功"
    talosctl bootstrap --nodes ${ipv4_patch}
    echo "talos引导成功!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    # 输出不包含 "error"，则认为命令执行成功，跳出循环
    break
  fi
done


while true; do
  # 执行命令并捕获其输出和退出状态
  output=$(eval "$kubectl_version" 2>&1)
  exit_code=$?
  # 检查命令输出是否包含 "error"
  if [[ $output == *"timeout"* ]]; then
    echo "访问k8s中，请等待2分钟，不要进行任何操作"
    talosctl kubeconfig -f
    sleep 120
  else
    echo "k8s访问成功!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    # 输出不包含 "error"，则认为命令执行成功，跳出循环
    break
  fi
done


talosctl service


# 输入验证函数

while true; do
  echo "开始检查etcd服务状态"
  service_status=$(talosctl service)
  if [[ $? -ne 0 ]]; then
      echo "获取服务状态失败。"
  fi

  etcd_status=$(echo "$service_status" | grep "^.* etcd .*")
  if [[ -z "$etcd_status" ]]; then
    echo "错误：在'talosctl service'命令输出中找不到etcd服务状态,请等待2分钟"
  fi

  expected_state="Running"
  state_value=$(echo "$etcd_status" | awk '{print $3}')

  if [[ "$state_value" == "$expected_state" ]]; then
    echo "etcd服务已进入预期状态：$expected_state"
    talosctl kubeconfig -f
    talosctl service
    kubectl get pods -A
    break
  else
    echo "etcd服务未处于预期状态。当前状态：$state_value"
  fi

  # 短暂等待，再次检查
  sleep 30
done


echo "开始检查k8s集群状态"
while true; do
  # 获取所有Pod的状态信息
  pod_statuses=$(kubectl get pods -A --output=json)

  # 检查是否有非Running状态的Pod
  non_running=$(echo "$pod_statuses" | jq -r '.items[] | select(.status.phase != "Running") | .metadata.namespace')

  if [[ -z $non_running ]]; then
    # 如果没有非Running状态的Pod，则执行下一步操作并退出循环
    echo "所有命名空间均处于Running状态"
    break
  fi

  # 输出当前非Running状态的Namespace列表
  echo "以下命名空间未处于Running状态："
  echo "$non_running"


  # 等待指定时间后再次检查
  echo "将在20秒后重试..."
  sleep 20
done


# 发送邮件方法
function send_config_files_by_email() {
    project_name=$1

    echo "请输入你部署的项目的名字，英文，若输入错误 请用ctrl+w撤回后重新输入"
    read project_name

    # 定义接收者列表
    recipients=("18742423211@139.com" "1553232697@qq.com" "18640549232@163.com")

    # 定义要发送的配置文件列表
    config_files=("/root/.kube/config" "/root/.talos/config")

    # 安装msmtp和mailx
    install_deps() {
        if command -v yum &> /dev/null; then
            echo "正在为CentOS/RHEL系统安装必要软件..."
            sudo yum install -y msmtp ca-certificates mailx
        else
            echo "无法识别的包管理器，请手动安装msmtp和mailx。"
        fi
    }



    # email方法
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

    # 定义自定义邮件正文内容
    k8s_body="这是Kubernetes配置文件... 项目名为：$project_name"
    talos_body="这是Talos系统配置文件... 项目名为：$project_name"

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
}

send_config_files_by_email "$1"



exit 0
