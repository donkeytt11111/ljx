if [ "$#" -ne 1 ]; then
    echo "用法: $0 <起始IP>"
    exit 1
fi

# 获取起始IP并设置IP范围
start_ip=$1
start_num=${start_ip##*.}
end_num=$((start_num + 4))

# 循环ping IP地址
for ((i=start_num; i<=end_num; i++)); do
    ip="${start_ip%.*}.${i}"
    echo "正在ping $ip..."
    if ping -c 1 -W 2 $ip &> /dev/null; then
        echo "$ip 可达。"
        echo "检测到可达IP，脚本执行结束。"
        break
    else
        echo "$ip 不可达。"
    fi
done
