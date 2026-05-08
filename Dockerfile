# Usamos una imagen base oficial de Python ligera
FROM python:3.11-slim

# Evitar que se generen archivos .pyc y salida sin buffer (mejores logs)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Crear un usuario no root por motivos de seguridad y asignarle un directorio home (-m)
RUN groupadd -r appuser && useradd -r -m -g appuser appuser

# Establecer el directorio de trabajo
WORKDIR /app

# Instalar dependencias del SO que podrían necesitar librerías de datos (como geopandas)
# y curl para el HEALTHCHECK, limpiando el caché de apt después.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar solo el archivo de requerimientos primero, para aprovechar el caché de Docker
COPY requirements.txt /app/

# Actualizar pip e instalar dependencias de Python (sin cachear)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar todo el código de la aplicación, asignando los permisos al usuario creado
COPY --chown=appuser:appuser . /app/

# Cambiar al usuario no root
USER appuser

# Exponer el puerto por el que sirve Streamlit
EXPOSE 8501

# Añadir una comprobación de salud para el despliegue
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:8501/_stcore/health || exit 1

# Comando por defecto para correr Streamlit (ajustado para que sea accesible externamente)
ENTRYPOINT ["streamlit", "run", "app/streamlit_app.py", "--server.port=8501", "--server.address=0.0.0.0"]