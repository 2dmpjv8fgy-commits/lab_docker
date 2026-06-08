FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./

# Теперь запускаем именно app.py
CMD ["python", "app.py"]
