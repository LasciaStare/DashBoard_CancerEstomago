# ---- Etapa 1: Builder ----
FROM python:3.11-slim as builder

WORKDIR /build
COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/build/install -r requirements.txt && \
    find /build/install -type d -name "tests" -exec rm -rf {} + && \
    find /build/install -type d -name "__pycache__" -exec rm -rf {} + && \
    find /build/install -name "*.pyc" -delete && \
    find /build/install -name "*.pyo" -delete

# ---- Etapa 2: Runner final ----
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/usr/local/lib/python3.11/site-packages

RUN groupadd -r appuser && useradd -r -m -g appuser appuser

# Instalar solo curl y librerías C mínimas para paquetes matemáticos
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar paquetes optimizados (sin test/caches) desde la etapa builder
COPY --from=builder /build/install/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /build/install/bin /usr/local/bin

COPY --chown=appuser:appuser . /app/

USER appuser
EXPOSE 8501

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:8501/_stcore/health || exit 1

ENTRYPOINT ["streamlit", "run", "app/streamlit_app.py", "--server.port=8501", "--server.address=0.0.0.0"]
