FROM harbor.example.com/main/python:3.12.5-slim
WORKDIR /app

RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py ./

EXPOSE 9102
CMD ["python3", "app.py"]
