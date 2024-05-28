#!/bin/bash
#集团文件夹下方执行
#执行之前确定/path/to/dhcpdb_create.pgsql有没有这个文件



source_config_path="/root/.kube/config"
helm_path="cncp-helm"
services_path="cncp-helm/cncp-basic-services/values.yaml"
core_path="cncp-helm/cncp-core-components/values.yaml"
v4_one_path=$1
v4_tow_path=$2
v6_one_path=$3
v6_tow_path=$4
ipv4_path="172.16.102.240-172.16.102.244"
ipv6_path="2408:8631:c02:ffa2::240-2408:8631:c02:ffa2::244"
v4_dns_path=$5
v4_dhcp_path=$6
v6_dns_path=$7
v6_dhcp_path=$8
ddi_file_path="cncp-helm/ddi-components/values.yaml"
sql_path=$9


# bak
#backup_suffix="_$(date +%Y%m%d%H%M%S).bak"
#cp "$services_path" "${services_path}${backup_suffix}"
#cp "$core_path" "${core_path}${backup_suffix}"

#echo "服务路径（$services_path）和核心路径（$core_path）的备份已完成。备份文件分别命名为："
#echo "${services_path}${backup_suffix}"
#echo "${core_path}${backup_suffix}"

# 定义要检查的文件路径
sql_file_path="/home/k8s/dhcpdb_create.pgsql"
#sql_netbox="/home/k8s/NetBoxCustomFields.csv"

# 使用test命令和-f选项检查文件是否存在
if test -f "$sql_file_path"; then
  echo "文件 /home/k8s/dhcpdb_create.pgsql 存在"
else
  echo "文件 /home/k8s/dhcpdb_create.pgsql 不存在 请检查sql文件"
  exit 1
fi



#/path/to/dhcpdb_create.pgsql

# 检查参数个数是否满足要求
if [[ $# -lt 4 ]]; then
    echo "使用错误！使用方法 sh ddi.sh 要配置的v4v6，240-244中的第一段 和第二段
    使用示例： sh ddi.sh 172.16.102.240 172.16.102.244 2408:8631:c02:ffa2::240 2408:8631:c02:ffa2::244"
    exit 1
    else
    echo "开始修改services.yaml文件"
fi

# 安装EPEL仓库
echo "正在检查并安装EPEL仓库..."
#yum install -y epel-release

# 清理yum缓存并更新
#yum clean all
#yum makecache

# 安装jq
echo "正在安装jq..."
yum install -y epel-release
yum install -y jq


if command -v jq &> /dev/null; then
    echo "jq安装成功！"
    jq --version
else
    echo "jq安装失败，请检查错误信息。"
fi

#修改services.yaml文件
sed -i "s/172.16.102.240-172.16.102.244/$v4_one_path-$v4_tow_path/g" "${services_path}"
if [[ $? -ne 0 ]]; then
    echo "修改ipv4文件失败"
    exit 1
fi
sed -i "s/2408:8631:c02:ffa2::240-2408:8631:c02:ffa2::244/$v6_one_path-$v6_tow_path/g" "${services_path}"
if [[ $? -ne 0 ]]; then
    GREEN="\033[0;32m"
    NC="\033[0m"  # No Color
    echo "修改services.yaml文件失败"
    exit 1
    else
    printf "${GREEN}修改 services.yaml 文件成功${NC}\n"
    printf "修改结果如下:\n\n"
    grep -A 2 "ipAddressPool:" "$services_path" | sed 's/^/    /'
    printf "\n"
fi



#修改core.yaml文件中的token
echo "正在将/root/.kube/config文件内容替换到 core配置文件中，请确保config只有一条记录"


ca_data=$(grep -Po 'certificate-authority-data:\s*\K.*' "$source_config_path")
cert_data=$(grep -Po 'client-certificate-data:\s*\K.*' "$source_config_path")
key_data=$(grep -Po 'client-key-data:\s*\K.*' "$source_config_path")

sed -i 's~^\(\s*\(certificate-authority-data\|certificate-authority-data\|certificate-authority-data\):\s*\).*~\1'"$ca_data"'~g' "$core_path"
sed -i 's~^\(\s*\(client-certificate-data\|client-certificate-data\|client-certificate-data\):\s*\).*~\1'"$cert_data"'~g' "$core_path"
sed -i 's~^\(\s*\(client-key-data\|client-key-data\|client-key-data\):\s*\).*~\1'"$key_data"'~g' "$core_path"

temp_file=$(mktemp)
grep -E '^ *\(certificate-authority-data\|client-certificate-data\|client-key-data\):' "$source_config_path" > "$temp_file"

if diff "$core_path" "$temp_file"; then
    echo "未进行任何替换"
else
    echo "替换已成功进行"
fi

rm "$temp_file"

#修改core.yaml文件中的dns dhcp
echo "修改core配置文件中的dns，请输入dns v4 IP"
echo "例如：172.16.102.145"
read v4_dns_path
echo "修改core配置文件中的dns，请输入dns v6 IP"
echo "例如：2408:8631:c02:ffa2::240"
read v6_dns_path
if [ $? -eq 0 ]; then
    echo "读取命令执行成功"
    echo "修改的的值为: $v4_dns_path"
    else
    echo "读取命令执行失败"
    fi
sed -i "s/172.16.102.240/${v4_dns_path}/g" "${core_path}"
sed -i "s/2408:8631:c02:ffa2::240/${v6_dns_path}/g" "${core_path}"

echo "修改core配置文件中的dhcp，请输入dhcp v4 IP"
read v4_dhcp_path
echo "修改core配置文件中的dhcp，请输入dhcp v6 IP"
read v6_dhcp_path
if [ $? -eq 0 ]; then
    echo "读取命令执行成功"
    echo "修改的的值为: $v4_dhcp_path"
    else
    echo "读取命令执行失败"
    fi
sed -i "s/172.16.102.241/${v4_dhcp_path}/g" "${core_path}"
sed -i "s/2408:8631:c02:ffa2::241/${v6_dhcp_path}/g" "${core_path}"
if [ $? -eq 0 ]; then
    echo "修改core配置文件成功"
    grep -A 5 "ddi:" "${core_path}"
    else
    echo "修改core配置文件失败"
    fi


#修改ddi配置文件
echo "修改ddi配置文件中的dns，请输入dns v4 IP"
read v4_dns_path
echo "修改ddi配置文件中的dns，请输入dns v6 IP"
read v6_dns_path
if [ $? -eq 0 ]; then
    echo "读取命令执行成功"
    echo "修改的的值为: $v4_dns_path"
    else
    echo "读取命令执行失败"
    fi
sed -i "s/172.16.102.240/${v4_dns_path}/g" "${ddi_file_path}"
sed -i "s/2408:8631:c02:ffa2::240/${v6_dns_path}/g" "${ddi_file_path}"


echo "修改ddi配置文件中的dhcp，请输入dhcp v4 IP"
read v4_dhcp_path
echo "修改ddi配置文件中的dhcp，请输入dhcp v6 IP"
read v6_dhcp_path
if [ $? -eq 0 ]; then
    echo "读取命令执行成功"
    echo "修改的的值为: $ddi_dhcp_path"
    else
    echo "读取命令执行失败"
    fi
sed -i "s/172.16.102.241/${v4_dhcp_path}/g" "${ddi_file_path}"
sed -i "s/2408:8631:c02:ffa2::241/${v6_dhcp_path}/g" "${ddi_file_path}"
if [ $? -eq 0 ]; then
    echo "修改ddi配置文件成功 结果为："
    grep -A 5 "ddi:" "${ddi_file_path}"
    else
    echo "修改core配置文件失败"
    fi

cd $helm_path


pwd
# 指定最大重试次数和等待时间
MAX_RETRIES=100
SLEEP_TIME=20
MAX_error=6
# 计数器初始化
retries=0


while true; do
  # 获取所有Pod的状态信息
  pod_statuses=$(kubectl get pods -A --output=json)

  # 检查是否有非Running状态的Pod
  non_running=$(echo "$pod_statuses" | jq -r '.items[] | select(.status.phase != "Running") | .metadata.namespace')

  if [[ -z $non_running ]]; then
    # 如果没有非Running状态的Pod，则执行下一步操作并退出循环
    echo "所有命名空间均处于Running状态。service下发成功"
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
  echo "将在$SLEEP_TIME秒后重试..."
  sleep $SLEEP_TIME
done

echo "开始下发service配置文件"

helm install cncp-basic-services ./cncp-basic-services/ --debug
if [[ $? -ne 0 ]]; then
      echo "下发service异常，正在执行卸载指令"
      helm uninstall cncp-basic-services
      else
      echo "下发service配置文件成功"
fi


# 主循环，用于检查Pod状态并决定是否继续等待或执行下一步操作
while true; do
  # 获取所有Pod的状态信息
  pod_statuses=$(kubectl get pods -A --output=json)

  # 检查是否有非Running状态的Pod
  non_running=$(echo "$pod_statuses" | jq -r '.items[] | select(.status.phase != "Running") | .metadata.namespace')

  if [[ -z $non_running ]]; then
    # 如果没有非Running状态的Pod，则执行下一步操作并退出循环
    echo "所有命名空间均处于Running状态。service下发成功"
    break
  fi

  # 输出当前非Running状态的Namespace列表
  echo "以下命名空间未处于Running状态："
  echo "$non_running"

  retries=$((retries + 1))
  if (( retries > MAX_RETRIES )); then
    # 如果达到最大重试次数，打印警告并退出脚本
    echo "达到最大重试次数，仍有命名空间未达到Running状态。退出脚本。"
    kubectl -n openebs  get pods | grep Completed |awk '{print$1}'|xargs kubectl -n openebs delete pods
    break
  fi

  # 等待指定时间后再次检查
  echo "将在$SLEEP_TIME秒后重试..."
  sleep $SLEEP_TIME
done


echo "开始下发ddi"
helm install ddi-components ./ddi-components/ --debug

if [[ $? -ne 0 ]]; then
      echo "下发ddi异常，正在执行卸载指令"
      helm uninstall ddi-components
      else
      echo "下发ddi配置文件成功"
fi

while true; do
  # 获取所有Pod的状态信息
  pod_statuses=$(kubectl get pods -A --output=json)

  # 检查是否有非Running状态的Pod
  non_running=$(echo "$pod_statuses" | jq -r '.items[] | select(.status.phase != "Running") | .metadata.namespace')

  if [[ -z $non_running ]]; then
    # 如果没有非Running状态的Pod，则执行下一步操作并退出循环
    echo "所有命名空间均处于Running状态。ddi下发成功"
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
  echo "将在$SLEEP_TIME秒后重试..."
  sleep $SLEEP_TIME
done

echo "开始下发core组件"
helm install cncp-core-components ./cncp-core-components/ --debug

if [[ $? -ne 0 ]]; then
      echo "下发core异常，正在执行卸载指令"
      helm uninstall cncp-core-components
      else
      echo "下发ddi配置文件成功"
fi

echo "开始创建taolos~yaml新pod"
kubectl create -f talos-dashboard.yaml

if [[ $? -ne 0 ]]; then
      echo "创建talospod成功"
      helm uninstall cncp-core-components
      else
      echo "创建talospod异常"
fi

while true; do
  # 获取所有Pod的状态信息
  pod_statuses=$(kubectl get pods -A --output=json)

  # 检查是否有非Running状态的Pod
  non_running=$(echo "$pod_statuses" | jq -r '.items[] | select(.status.phase != "Running") | .metadata.namespace')

  if [[ -z $non_running ]]; then
    # 如果没有非Running状态的Pod，则执行下一步操作并退出循环
    echo "所有命名空间均处于Running状态。core下发成功"
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
  echo "将在$SLEEP_TIME秒后重试..."
  sleep $SLEEP_TIME
done



# SQL处理
function configure_postgres() {
    yum install -y *postgresql*
    echo "请输入你要指定的数据库IP地址！你master1的地址"
    read sql_path
    local db_host="${sql_path}"
    local db_port="32002"
    local db_user="root"
    local db_password="Passw0rd@MY"

    # Create databases, users, and grant privileges
    psql -h "$db_host" -p "$db_port" -U "$db_user" <<-EOSQL
        CREATE DATABASE netbox;
        CREATE USER netbox WITH PASSWORD '$db_password';
        GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;

        CREATE DATABASE kea;
        CREATE USER kea WITH PASSWORD '$db_password';
        GRANT ALL PRIVILEGES ON DATABASE kea TO kea;
        
        SHOW TIMEZONE;
        SELECT * FROM pg_timezone_names WHERE name = current_setting('TIMEZONE');
        SET TIME ZONE 'Asia/Shanghai';
EOSQL

    # Login to kea database and execute dhcpdb_create.pgsql script
    psql -h "$db_host" -p "$db_port" -d kea -U kea -f "/home/k8s/dhcpdb_create.pgsql" <<< "$db_password"
}
# Call the function to perform the configuration
configure_postgres



DEPLOYMENT_TYPE_SINGLE="单机"
DEPLOYMENT_TYPE_MULTI_MASTER="多master"


printf "\n开始部署协议交换服务，请选择部署模式：（如果单机部署则输入1 如果是多master部署 则直接回车跳过该步骤，等待最后一个master部署完成后选择2）\n"
printf "1. ${DEPLOYMENT_TYPE_SINGLE}\n"
printf "2. ${DEPLOYMENT_TYPE_MULTI_MASTER}\n\n请输入对应编号：\n"


read -p "请选择(1/${DEPLOYMENT_TYPE_SINGLE}, 2/${DEPLOYMENT_TYPE_MULTI_MASTER})：" selection


case $selection in
    1)
        kubectl apply -f nginx-ds.yaml
        ;;
    2)
        kubectl apply -f nginx-deployment.yaml
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

  retries=$((retries + 1))
  if (( retries > MAX_RETRIES )); then
    # 如果达到最大重试次数，打印警告并退出脚本
    echo "达到最大重试次数，仍有命名空间未达到Running状态。退出脚本。"
    exit 1
  fi

  # 等待指定时间后再次检查
  echo "将在$SLEEP_TIME秒后重试..."
  sleep $SLEEP_TIME
done

