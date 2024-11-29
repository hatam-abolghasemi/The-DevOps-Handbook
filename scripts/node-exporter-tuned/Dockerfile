FROM harbor.example.com/main/python:3.12.5-slim
WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py ./

EXPOSE 9101
CMD ["python3", "app.py"]
