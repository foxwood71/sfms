FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# main.py의 FastAPI 인스턴스를 실행
CMD ["uvicorn", "main.app", "--host", "0.0.0.0", "--port", "8000", "--reload"]