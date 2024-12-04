# Sử dụng image Consul làm base
FROM hashicorp/consul:1.20.1

# Cài đặt Python và pip trên Alpine
RUN apk add --no-cache python3 py3-pip

# Thiết lập thư mục làm việc trong container
WORKDIR /app

# Sao chép các tệp cần thiết vào container
COPY requirements.txt .
COPY main.py .

# Tạo môi trường ảo Python và cài đặt các gói trong đó
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt

# Đặt môi trường ảo làm Python mặc định
ENV PATH="/app/venv/bin:$PATH"