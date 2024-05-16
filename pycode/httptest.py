import requests
import time


class PeriodicURLMonitor:
    def __init__(self, url: str, interval_seconds: int, timeout_seconds: int):
        self.url = url
        self.interval_seconds = interval_seconds
        self.timeout_seconds = timeout_seconds

    def run(self):

        while True:
            current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())

            try:
                # 添加超时参数到 requests.get() 函数调用中
                response = requests.get(self.url, timeout=self.timeout_seconds)
                status_code = response.status_code
                print(f"{current_time} - 访问成功, 响应状态码: {status_code}")
            except requests.exceptions.Timeout as te:
                # 处理请求超时异常
                status_code = "未知 (请求超时)"
                print(f"{current_time} - 访问失败, 异常信息: 请求超时")
            except requests.exceptions.RequestException as re:
                # 其他请求异常继续按照原逻辑处理
                status_code = "未知 (请求异常)"
                print(f"{current_time} - 访问失败, 异常信息: {str(re)}")

            print(f"{current_time} - URL: {self.url}, 状态码: {status_code}\n")
            time.sleep(self.interval_seconds)



monitor = PeriodicURLMonitor("http://testa.com", 2, 5)
monitor.run()