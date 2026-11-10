# Contenedor 1: API de la calculadora (Flask + Gunicorn).
# Se construye desde la raiz del repositorio para reutilizar calculadora.py:
#   docker build -f app/Dockerfile -t calculadora-app:1.0 .

# Imagen oficial de Python con version fija (no "latest").
FROM python:3.13.18-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Primero las dependencias, para aprovechar la cache de capas.
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY calculadora.py .
COPY app/main.py .

# La aplicacion no corre como root.
RUN useradd --create-home --uid 1000 appuser
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/salud')"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--access-logfile", "-", "main:app"]
