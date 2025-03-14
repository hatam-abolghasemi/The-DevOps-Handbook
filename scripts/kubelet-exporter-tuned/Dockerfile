FROM harbor.alo-data.com/main/python:3.12.5-slim
RUN useradd -m appuser && mkdir -p /app && chown -R appuser:appuser /app
WORKDIR /app

COPY --chown=appuser:appuser requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appuser app.py ./
USER appuser
EXPOSE 10251

CMD ["python", "app.py"]
