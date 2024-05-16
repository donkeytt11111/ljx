#!/bin/bash

# 定义变量
ipv4=$1
GATEWAY=$2
my_PREFIX=$3
config_file="/home/ljx/ifcfg-ens33"
backup_file="${config_file}.bak"

# 参数校验
validate_params() {
  if [[ -z "$ipv4" || -z "$GATEWAY" || -z "$my_PREFIX" ]]; then
    echo "使用错误！用法: sh ip.sh ip地址 网关地址 掩码
示例用法: sh ip_config.sh 192.168.1.100 192.168.1.1 24"
    exit 1
  fi

  if ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "错误：无效的IP地址格式"
    exit 1
  fi

  if ! [[ $GATEWAY =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "错误：无效的网关地址格式"
    exit 1
  fi

  if ! [[ $my_PREFIX =~ ^[0-9]{1,2}$ ]]; then
    echo "错误：无效的子网掩码长度"
    exit 1
  fi
}

# 文件操作验证与备份
check_and_backup_file() {
  if [[ ! -f "$config_file" ]]; then
    echo "原文件不存在"
    exit 1
  fi

  if ! [[ -r "$config_file" && -w "$config_file" ]]; then
    echo "权限不足"
    exit 1
  fi

  if ! [[ -w "$(dirname "$backup_file")" ]]; then
    echo "写入权限不足"
    exit 1
  fi

  if ! cp -i "$config_file" "$backup_file"; then
    echo "复制异常"
    exit 1
  fi

  echo "备份完成"
}

# 修改配置文件
update_config() {
  set -e
  sed -i -e "/IPADDR=/ s/.*/IPADDR=${ipv4}/g" -e "/GATEWAY=/ s/.*/GATEWAY=${GATEWAY}/g" -e "/PREFIX=/ s/.*/PREFIX=${my_PREFIX}/g" "$config_file" || { echo "修改配置文件失败"; exit 1; }

  # 输出修改后的结果
  #echo "查看修改后的结果:" `grep -E "IPADDR|GATEWAY|PREFIX" "${config_file}"`
  
  GREEN="\033[1;32m"
  NC="\033[0m"  # No Color，用于恢复默认颜色
  echo -e "\n${GREEN}查看修改后的结果:${NC}"
  grep -E "IPADDR|GATEWAY|PREFIX" "${config_file}" | sed 's/^/  /'  # 前缀添加两个空格以缩进显示
  echo ""  # 输出一个空行以增加可读性
  # 重启网络服务（可选，根据实际需求启用）
  # systemctl restart network || echo "网卡重启失败"
}

# 执行主要逻辑
validate_params
check_and_backup_file
update_config
echo "网卡重启成功"
