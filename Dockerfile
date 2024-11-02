FROM python:3.9.8-slim-bullseye

LABEL author="mybsdc <mybsdc@gmail.com>" \
    maintainer="luolongfei <luolongf@gmail.com>"

ENV TZ Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# set -eux e: 脚本只要发生错误，就终止执行 u: 遇到不存在的变量就会报错，并停止执行 x: 在运行结果之前，先输出执行的那一行命令
RUN set -eux; \
    # 安装基础依赖工具
    apt-get update; \
    apt-get install -y --no-install-recommends \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    lsb-release \
    libwayland-server0 \
    libgbm1 \
    curl \
    unzip \
    wget \
    xdg-utils \
    xvfb; \
    # 清除非明确安装的推荐的或额外的扩展 configure apt-get to automatically consider those non-explicitly installed suggestions/recommendations as orphans
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    # It removes everything but the lock file from /var/cache/apt/archives/ and /var/cache/apt/archives/partial/
    apt-get clean; \
    # 删除包信息缓存
    rm -rf /var/lib/apt/lists/*
# 非交互式安装，避免告警
ARG DEBIAN_FRONTEND=noninteractive

# ARG CHROME_VERSION=96.0.4664.45-1
ARG CHROME_VERSION=115.0.5776.0
# ARG CHROME_DRIVER_VERSION=96.0.4664.45
ARG CHROME_DRIVER_VERSION=115.0.5776.0

ARG CHROME_DOWNLOAD_URL=https://storage.googleapis.com/chrome-for-testing-public/${CHROME_DRIVER_VERSION}/linux64/chrome-linux64.zip
ARG CHROME_DRIVER_DOWNLOAD_URL=https://storage.googleapis.com/chrome-for-testing-public/${CHROME_DRIVER_VERSION}/linux64/chromedriver-linux64.zip



# 下载并安装 Chrome
RUN wget --no-verbose -O /tmp/chrome.zip "${CHROME_DOWNLOAD_URL}" || { echo "Chrome download failed"; exit 1; }; \
    unzip /tmp/chrome.zip || { echo "Chrome unzip failed"; exit 1; }; \
    rm /tmp/chrome.zip; \
    mv chrome-linux64 /usr/bin/ || { echo "Failed to move Chrome folder"; exit 1; }; \
    chmod +x /usr/bin/chrome-linux64/chrome || { echo "Failed to make Chrome executable"; exit 1; }; \
    /usr/bin/chrome-linux64/chrome --version || { echo "Failed to get Chrome version"; exit 1; }; \
    ln -s /usr/bin/chrome-linux64/chrome /usr/local/bin/chrome

# 下载并启用 ChromeDriver
RUN wget --no-verbose -O chromedriver.zip "${CHROME_DRIVER_DOWNLOAD_URL}" || { echo "ChromeDriver download failed"; exit 1; }; \
    unzip chromedriver.zip || { echo "ChromeDriver unzip failed"; exit 1; }; \
    rm chromedriver.zip; \
    mv chromedriver-linux64 /usr/bin/ || { echo "Failed to move ChromeDriver"; exit 1; }; \
    chmod +x /usr/bin/chromedriver-linux64/chromedriver || { echo "Failed to make ChromeDriver executable"; exit 1; }; \
    /usr/bin/chromedriver-linux64/chromedriver --version || { echo "Failed to get ChromeDriver version"; exit 1; }; \
    ln -s /usr/bin/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver

# Add Chrome and ChromeDriver to PATH
ENV PATH="/usr/bin/chrome-linux64:/usr/bin/chromedriver-linux64:${PATH}"

WORKDIR /app

COPY . ./

RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --no-cache-dir -r requirements.txt

VOLUME ["/conf", "/app/logs"]

EXPOSE 8080

RUN dos2unix docker-entrypoint.sh; \
    cp docker-entrypoint.sh /usr/local/bin/; \
    chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["sh", "-c", "docker-entrypoint.sh"]

CMD ["crond", "-f"]
