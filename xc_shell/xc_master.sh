#!/bin/bash

#talos目录下执行

source_file="controlplane.yaml"

target_name_pattern=$1
v4_hostname_path=$2
v6_hostname_path=$3
linshi_path=$4

# 检查参数个数是否满足要求
if [[ $# -lt 4 ]]; then
    echo "使用错误！使用方法 sh file.sh 要生成的controlplane.yaml文件名 要设置的master节点的主机IP(v4) + 要设置的master节点的主机IP(v6) + DHCP临时IP地址主机位
    使用示例： sh master.sh 2 172.16.102.146 2408:8631:c02:ffa2::146 172.16.102.225"
    exit 1
fi


new_filename="controlplane${target_name_pattern}.yaml"


cp "$source_file" "$new_filename"



if [ $? -eq 0 ]; then
  echo "复制成功 新文件名为'$new_filename'."
else
  echo "请将脚本放至talos目录下执行"
  exit 1
fi


if [ -f "$new_filename" ]; then
  echo "文件'$new_filename'存在."
else
  echo "文件'$new_filename'不存在."
  exit 1
fi


if [ -n "$2" ]; then
    # 使用颜色输出
    GREEN='\033[0;32m'
    NC='\033[0m'  # No Color

    echo -e "${GREEN}开始修改${new_filename}${NC}"
    
    sed -i "s/hostname: cncp-ms-01/hostname: cncp-ms-0${target_name_pattern}/g" "${new_filename}"
    sed -i "98s/.*/                - ${v4_hostname_path}\/24/" "${new_filename}"
    sed -i "99s/.*/                - ${v6_hostname_path}\/64/" "${new_filename}"

    # 格式化文本输出
    echo -e "\n${GREEN}修改成功:${NC}"
    cat "${new_filename}" | grep -A 8 "    network:
        hostname: cncp-ms-0" | sed 's/^/    /'
else
    echo "修改master文件失败"
    exit 1
fi

echo "开始下发master配置文件"
talosctl apply-config --insecure -n ${linshi_path} --file "${new_filename}"
if [[ $? -ne 0 ]]; then
      echo "下发中，请等待"
      else
      echo "下发master配置文件成功"
fi

#判断状态
while true; do
  echo "开始检查master：etcd服务状态"
  service_status=$(talosctl service -n ${v4_hostname_path})
  if [[ $? -ne 0 ]]; then
      echo "获取服务状态失败。"
  fi

  etcd_status=$(echo "$service_status" | grep "^.* etcd .*")
  if [[ -z "$etcd_status" ]]; then
    echo "错误：在'talosctl service'命令输出中找不到etcd服务状态。"
  fi

  expected_state="Running"
  state_value=$(echo "$etcd_status" | awk '{print $3}')

  if [[ "$state_value" == "$expected_state" ]]; then
      echo "etcd服务已进入预期状态：$expected_state"
      talosctl service -n ${v4_hostname_path}
      break
  else
      #echo "etcd服务未处于预期状态。当前状态：$state_value"
      #read linshi_path
      #if [ $? -eq 0 ]; then
      #    echo "读取命令执行成功"
      #    echo "修改的的值为: $linshi_path"
      #else
      #    echo "读取命令执行失败"
      #fi
      #talosctl apply-config --insecure -n 172.16.102.${linshi_path} --file "${new_filename}"
      #if [[ $? -ne 0 ]]; then
      #    echo "引导新节点失败。"
      echo "请等待2分钟"
  fi
  sleep 120
done


cd ..
cd cncp-helm


DEPLOYMENT_TYPE_SINGLE="单机"
DEPLOYMENT_TYPE_MULTI_MASTER="多master"


printf "\n开始部署协议交换服务，请选择部署模式，如果你部署的是三台机器请在最后一台执行该指令 不输入1和2直接回车跳过即可\n"
printf "1. ${DEPLOYMENT_TYPE_SINGLE}\n"
printf "2. ${DEPLOYMENT_TYPE_MULTI_MASTER}\n\n请输入对应编号：\n"


read -p "请选择(1/${DEPLOYMENT_TYPE_SINGLE}, 2/${DEPLOYMENT_TYPE_MULTI_MASTER})：" selection


case $selection in
    1)
        kubectl apply -f nginx-deployment.yaml
        ;;
    2)
        kubectl apply -f nginx-ds.yaml
        ;;
    *)
        printf "错误！无效输入。请确保输入1或2。\n"
        ;;
esac


while true; do
  # 获取所有Pod的状态信息
  pod_statuses=$(kubectl get pods -A --output=json)

  # 检查是否有非Running状态的Pod
  non_running=$(echo "$pod_statuses" | jq -r '.items[] | select(.status.phase != "Running") | .metadata.namespace')

  if [[ -z $non_running ]]; then
    # 如果没有非Running状态的Pod，则执行下一步操作并退出循环
    echo "\n协议交换部署脚本执行完毕。"
    kubectl get pods --all-namespaces -o wide
    break
  fi

  # 输出当前非Running状态的Namespace列表
  echo "以下命名空间未处于Running状态："
  echo "$non_running"

#  retries=$((retries + 1))
#  if (( retries > MAX_RETRIES )); then
#    # 如果达到最大重试次数，打印警告并退出脚本
#    echo "达到最大重试次数，仍有命名空间未达到Running状态。退出脚本。"
#  fi

  # 等待指定时间后再次检查
  echo "将在20秒后重试..."
  sleep 20
done




exit 0 
