FROM python:3.10.15-slim-bullseye AS builder

WORKDIR /app
COPY requirements.txt /app
RUN pip install --user --no-cache-dir --upgrade -r requirements.txt


FROM python:3.10.15-slim-bullseye
WORKDIR /app

COPY --from=builder /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH

CMD ["python", "app.py"]
