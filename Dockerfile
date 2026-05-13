# ============================================================
# STAGE 1 - Builder: instala dependencias en entorno limpio
# ============================================================
FROM python:3.11-slim AS builder

WORKDIR /build

# Copiar solo el archivo de dependencias primero (cache de capas)
COPY requirements.txt .

# Instalar dependencias en directorio local para copiarlas luego
RUN pip install --upgrade pip \
    && pip install --prefix=/install --no-cache-dir -r requirements.txt

# ============================================================
# STAGE 2 - Runtime: imagen final mínima y segura
# ============================================================
FROM python:3.11-slim AS runtime

# Metadatos de la imagen
LABEL maintainer="Innovatech Chile" \
      app="frontend-flask" \
      version="1.0"

# Crear usuario no-root para ejecutar la app (mínimo privilegio)
RUN groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid appgroup --no-create-home --shell /bin/false appuser

WORKDIR /app

# Copiar dependencias instaladas desde el stage builder
COPY --from=builder /install /usr/local

# Copiar el código de la aplicación
COPY --chown=appuser:appgroup . .

# Eliminar archivos innecesarios para reducir superficie de ataque
RUN find . -name "*.pyc" -delete \
    && find . -name "__pycache__" -delete \
    && rm -f .env.example

# Exponer el puerto del servidor Flask
EXPOSE 5000

# Cambiar al usuario sin privilegios
USER appuser

# Variables de entorno por defecto (sobreescribibles en runtime)
ENV PORT=5000 \
    DEBUG=False \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Healthcheck para monitoreo del contenedor
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000')" || exit 1

# Comando de inicio
CMD ["python", "app.py"]
