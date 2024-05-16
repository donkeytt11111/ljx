#!bin/bash
while true; do
  echo "开始检查etcd服务状态"
  service_status=$(talosctl service)
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
    talosctl service
    kubectl get pods -A
    break
  else
    echo "etcd服务未处于预期状态。当前状态：$state_value"
    #echo "请输入你要执行bootstrap的ipv4主机位"
    #read ipv4_path
    #if [ $? -eq 0 ]; then
    #    echo "读取命令执行成功"
    #    echo "修改的的值为: $ipv4_path"
    #else
    #    echo "读取命令执行失败"
    #fi
    #talosctl bootstrap --nodes 172.16.102.${ipv4_path}
    #if [[ $? -ne 0 ]]; then
    #    echo "引导新节点失败。"
    #    exit 1
    #fi
  fi

  # 短暂等待，再次检查
  sleep 5
done

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

  retries=$((retries + 1))
  if (( retries > MAX_RETRIES )); then
    # 如果达到最大重试次数，打印警告并退出脚本
    echo "达到最大重试次数，仍有命名空间未达到Running状态。退出脚本。"
    exit 1
  fi

  # 等待指定时间后再次检查
  echo "将在20秒后重试..."
  sleep 20
done
