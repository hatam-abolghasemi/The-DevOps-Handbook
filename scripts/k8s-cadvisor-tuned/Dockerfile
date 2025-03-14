FROM harbor.alo-data.com/main/python:3.12.5-slim
WORKDIR /app

RUN pip install flask requests
COPY app.py ./

CMD ["python", "app.py"]
