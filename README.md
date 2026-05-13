# 🌐 Frontend – Innovatech Chile (Flask + Docker + CI/CD)

Aplicación web desarrollada en **Python/Flask** que gestiona usuarios mediante una interfaz web. Se conecta con el Backend API y se despliega en AWS EC2 mediante contenedores Docker con pipeline CI/CD automatizado.

---

## 📋 Tabla de contenidos

- [Stack tecnológico](#stack-tecnológico)
- [Arquitectura](#arquitectura)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Configuración de variables de entorno](#configuración-de-variables-de-entorno)
- [Ejecución local (sin Docker)](#ejecución-local-sin-docker)
- [Ejecución con Docker](#ejecución-con-docker)
- [Ejecución con Docker Compose](#ejecución-con-docker-compose)
- [Pipeline CI/CD](#pipeline-cicd)
- [Secrets requeridos en GitHub](#secrets-requeridos-en-github)
- [Despliegue en AWS EC2](#despliegue-en-aws-ec2)

---

## 🛠 Stack tecnológico

| Componente | Tecnología | Versión |
|---|---|---|
| Lenguaje | Python | 3.11 |
| Framework web | Flask | ^2.3.3 |
| Template engine | Jinja2 | ^3.1.2 |
| HTTP client | requests | ^2.31.0 |
| Variables de entorno | python-dotenv | ^1.0.0 |
| Contenedor | Docker | 24+ |
| Registry de imágenes | Docker Hub | - |
| CI/CD | GitHub Actions | - |
| Infraestructura | AWS EC2 | - |

---

## 🏗 Arquitectura

```
Internet
    │
    ▼
[EC2 Frontend - Subred Pública]
  Puerto 5000 (expuesto via Security Group)
  Contenedor: innovatech-frontend
    │
    │  HTTP interno (IP privada)
    ▼
[EC2 Backend - Subred Privada]
  Puerto 3000 (solo accesible desde Frontend)
  Contenedor: innovatech-backend
    │
    ▼
  [MySQL - red Docker interna]
  Puerto 3306 (solo contenedor backend)
```

> ⚠️ **Solo el Frontend es accesible desde Internet.** El Backend opera en subred privada, accesible únicamente desde el Frontend via Security Groups de AWS.

---

## 📁 Estructura del proyecto

```
frontend/
├── .github/
│   └── workflows/
│       └── deploy-frontend.yml   # Pipeline CI/CD
├── templates/
│   ├── base.html
│   ├── index.html
│   ├── crear_usuario.html
│   ├── editar_usuario.html
│   ├── 404.html
│   └── 500.html
├── app.py                        # Aplicación Flask principal
├── requirements.txt              # Dependencias Python
├── Dockerfile                    # Multi-stage build
├── docker-compose.yml            # Stack completo (dev local)
├── .env.example                  # Plantilla de variables de entorno
├── .gitignore
└── README.md
```

---

## ⚙️ Configuración de variables de entorno

```bash
# Copiar plantilla
cp .env.example .env

# Editar con tus valores
nano .env
```

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `PORT` | Puerto del servidor Flask | `5000` |
| `DEBUG` | Modo debug (False en producción) | `False` |
| `BACKEND_URL` | URL del Backend API | `http://localhost:3000` |
| `SECRET_KEY` | Clave secreta para sesiones Flask | *(requerida)* |

---

## 🐍 Ejecución local (sin Docker)

```bash
# 1. Crear entorno virtual
python -m venv venv
source venv/bin/activate        # Linux/Mac
venv\Scripts\activate           # Windows

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Configurar variables de entorno
cp .env.example .env
# Editar .env con BACKEND_URL apuntando al backend local

# 4. Iniciar la aplicación
python app.py
# Disponible en: http://localhost:5000
```

---

## 🐳 Ejecución con Docker

```bash
# Construir la imagen (multi-stage build)
docker build -t innovatech-frontend:latest .

# Ejecutar el contenedor
docker run -d \
  --name innovatech-frontend \
  -p 5000:5000 \
  -e BACKEND_URL=http://<IP-BACKEND>:3000 \
  -e SECRET_KEY=mi_clave_segura \
  innovatech-frontend:latest

# Ver logs del contenedor
docker logs -f innovatech-frontend

# Verificar estado
docker ps --filter "name=innovatech-frontend"
```

---

## 🐙 Ejecución con Docker Compose

```bash
# Configurar variables de entorno
cp .env.example .env
nano .env  # Completar con valores reales

# Levantar el stack completo (frontend + backend + mysql)
docker compose up -d

# Ver logs de todos los servicios
docker compose logs -f

# Ver logs solo del frontend
docker compose logs -f frontend

# Detener el stack
docker compose down

# Detener y eliminar volúmenes (¡borra datos!)
docker compose down -v
```

---

## 🔄 Pipeline CI/CD

El pipeline se activa automáticamente con cada `push` a la rama **`deploy`**.

### Flujo del pipeline

```
Push → rama deploy
        │
        ▼
   [Job 1: build-and-push]
   ├── Checkout del código
   ├── Setup Docker Buildx
   ├── Login en Docker Hub
   ├── Build imagen (multi-stage)
   └── Push imagen a Docker Hub
        │
        ▼ (solo si Job 1 exitoso)
   [Job 2: deploy-to-ec2]
   ├── Conexión SSH a EC2 Frontend
   ├── Pull imagen más reciente
   ├── Detener contenedor anterior
   ├── Iniciar nuevo contenedor
   └── Verificar estado del despliegue
```

### Activar el pipeline

```bash
# Trabajar en rama main/feature
git checkout main
git add .
git commit -m "feat: actualización del frontend"

# Hacer merge a rama deploy para activar CI/CD
git checkout deploy
git merge main
git push origin deploy
# ↑ Esto activa automáticamente el pipeline
```

---

## 🔐 Secrets requeridos en GitHub

Configurar en: `Repositorio → Settings → Secrets and variables → Actions`

| Secret | Descripción |
|---|---|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Access Token de Docker Hub (no la contraseña) |
| `EC2_FRONTEND_HOST` | IP pública de la instancia EC2 Frontend |
| `EC2_USERNAME` | Usuario SSH de EC2 (`ec2-user` o `ubuntu`) |
| `EC2_SSH_PRIVATE_KEY` | Contenido completo de la clave `.pem` de EC2 |
| `BACKEND_URL` | URL del backend (`http://<IP-privada-backend>:3000`) |
| `SECRET_KEY` | Clave secreta para sesiones Flask |

---

## ☁️ Despliegue en AWS EC2

### Requisitos previos en la instancia EC2

```bash
# Instalar Docker en la instancia EC2 (Amazon Linux 2)
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

### Verificar despliegue

```bash
# En la instancia EC2 Frontend
docker ps
docker logs innovatech-frontend

# Verificar acceso desde navegador
curl http://localhost:5000
```

### Configuración Security Group (AWS)

| Tipo | Puerto | Protocolo | Origen |
|---|---|---|---|
| SSH | 22 | TCP | Tu IP |
| HTTP personalizado | 5000 | TCP | 0.0.0.0/0 |

---

## 📝 Notas sobre el Dockerfile (multi-stage)

El Dockerfile usa **multi-stage build** para optimizar la imagen final:

- **Stage `builder`**: Instala todas las dependencias en un entorno limpio
- **Stage `runtime`**: Copia solo lo necesario → imagen más pequeña y segura

Además implementa:
- ✅ **Usuario no-root** (`appuser`) para mínimo privilegio
- ✅ **Limpieza de capas** (archivos `.pyc` y `__pycache__` eliminados)
- ✅ **Healthcheck** integrado para monitoreo automático
- ✅ **Variables de entorno** explícitas y seguras

---

## 🔍 Troubleshooting

```bash
# Ver logs del contenedor
docker logs innovatech-frontend

# Entrar al contenedor para depuración
docker exec -it innovatech-frontend /bin/sh

# Verificar variables de entorno dentro del contenedor
docker exec innovatech-frontend env

# Reiniciar el contenedor
docker restart innovatech-frontend
```
