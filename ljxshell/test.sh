echo "开始检查k8s集群状态"
while true; do
  # 尝试获取所有Pod的状态信息，直到成功
  while true; do
    pod_statuses=$(kubectl get pods -A --output=json 2>&1)
    if [[ $? -eq 0 ]]; then  # 如果命令成功执行，跳出内层循环
      break
    fi
    echo "无法获取Pod信息，可能是网络问题或权限不足。等待5秒后重试..."
    talosctl kubeconfig
    sleep 5
  done

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

  # 检查节点cncp-ms-01的污点
  echo "正在检查污点"
  output_taint=$(kubectl describe node cncp-ms-01 | grep 'Taints:\s*<none>')

  if [ -n "$output_taint" ]; then
    echo "不存在污点"
  else
    echo "存在污点，正在清除..."
    kubectl taint node cncp-ms-01 node-role.kubernetes.io/control-plane-
    echo "污点清除成功"
  fi

  # 等待指定时间后再次检查
  echo "将在20秒后检查集群状态..."
  sleep 20
done
