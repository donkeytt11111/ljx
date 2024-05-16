#!/bin/bash
# 用于替换文本文件中的字符串的简单脚本
# 参数检查
worker_file="worker.yaml"
worker_ip="$1"
master_ip="$2"
xiafa="$3"
worker_xiafa="talosctl apply-config --insecure -n 172.16.102.${xiafa} --file worker.yaml"

# 检查输入参数数量
if [ $# -ne 3 ]; then
    echo "使用错误！使用方法为：sh worker.sh workIP主机位 masterIP主机位 DHCP下发地址主机位 "
    exit 1
fi

# 封装  IP 替换函数
replace_worker_ip() {
    local pattern="$1"
    local replacement="$2"
    sed -i "s#${pattern}#${replacement}#g" "${worker_file}"
}


replace_worker_ip "- ip: 172.16.102.102" "- ip: 172.16.102.${master_ip}"
replace_worker_ip "endpoint: https://172.16.102.102:6443" "endpoint: https://172.16.102.${master_ip}:6443"


replace_worker_ip "- 172.16.102.102" "- 172.16.102.${worker_ip}"
replace_worker_ip "- 2408:8631:c02:ffa2::102" "- 2408:8631:c02:ffa2::${worker_ip}"


RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color


echo -e "${BLUE}替换完成！替换后 master1:${NC}"
echo -e "\t${YELLOW}extraHostEntries:${NC}"
grep -A 2 'extraHostEntries:' ${worker_file}

echo -e "${BLUE}替换完成！替换后 master2:${NC}"
echo -e "\t${YELLOW}endpoint:${NC}"
grep -A 2 'endpoint: https' ${worker_file}

echo -e "${BLUE}替换完成！替换后 worker:${NC}"
echo -e "\t${YELLOW}addresses:${NC}"
grep -A 2 'addresses:' ${worker_file}


echo -ne "\033[0m"


##下发配置文件
#if [ -n "$3" ];then
#    echo "开始下发配置文件"
#    xiafa=$(talosctl apply-config --insecure -n 172.16.102.${xiafa} --file worker.yaml)
#    echo "下发成功：$xiafa 请等待30秒"
#    else
#    echo "配置文件下发异常"
#    exit 1
#fi

echo "开始下发配置文件"
while true; do
  # 执行命令并捕获其输出和退出状态
  output=$(eval "$worker_xiafa" 2>&1)
  exit_code=$?
  # 检查命令输出是否包含 "error"
  if [[ $output == *"error"* ]]; then
    echo "下发集群异常请稍等，...请等待2分钟，不要进行任何操作"
    sleep 180
  else
    echo "下发集群中，...请等待2分钟，不要进行任何操作"
    sleep 180
    # 输出不包含 "error"，则认为命令执行成功，跳出循环
    break
  fi
done


talosctl service -n 172.16.102.${worker_ip}
