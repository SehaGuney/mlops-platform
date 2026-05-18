FROM python:3.11-slim as builder 
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/packages -r requirements.txt


FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /app/packages /app/packages
ENV PYTHONPATH=/app/packages
COPY . . 
RUN python3 app/train.py
CMD ["python3", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]