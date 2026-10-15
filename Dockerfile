# syntax=docker/dockerfile:1

# Python 3.11: newest version with prebuilt wheels for psycopg2-binary 2.9.5.

# ---------- Stage 1: build ----------
FROM python:3.11-slim AS builder

WORKDIR /app

# Isolated virtualenv, copied as a whole to the runtime stage.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Dependency manifest first so this layer stays cached until it changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---------- Stage 2: runtime ----------
FROM python:3.11-slim

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN useradd --system --uid 10001 --no-create-home appuser

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY app.py .

USER appuser
EXPOSE 8003

# gunicorn ignores PORT (only read by app.run); the bind defines the port.
CMD ["gunicorn", "--bind", "0.0.0.0:8003", "--workers", "2", "app:app"]
