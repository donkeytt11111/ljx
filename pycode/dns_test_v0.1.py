import dns.resolver
import datetime
import time

def check_dns_resolution(domain, nameserver):
    resolver = dns.resolver.Resolver()
    resolver.nameservers = [nameserver]
    try:
        answers = resolver.resolve(domain, 'A')
        ip_addresses = [str(answer) for answer in answers]
        result_text = f"解析成功: {', '.join(ip_addresses)}"
        status = "成功"
    except dns.exception.DNSException as e:
        result_text = f"解析失败: {e}"
        status = "失败"
    return result_text, status

def main():
    domains = ["www.example.com", "www.google.com"]
    nameservers = ["2408:8631:c02:ffa2::70", "8.8.8.8"]
    stop_after_seconds = 60 * 100 
    start_time = time.time()

    while time.time() - start_time < stop_after_seconds:
        for domain in domains:
            print(f"开始检查域名: {domain}")
            for nameserver in nameservers:
                print(f"使用DNS服务器: {nameserver}")
                now = datetime.datetime.now()
                result, status = check_dns_resolution(domain, nameserver)
                print(f"{now} - {result}")
                if status == "成功":
                    print(f"DNS解析成功: {domain} -> {nameserver}")
                else:
                    print(f"DNS解析失败: {domain} -> {nameserver}")
                time.sleep(1)  
        print("一轮检查完毕，准备开始下一轮...\n")


if __name__ == "__main__":
    main()