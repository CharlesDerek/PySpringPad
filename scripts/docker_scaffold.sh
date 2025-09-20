#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# ensure base dirs
mkdir -p docker/flask docker/fastapi docker/django

# .env.example (only if missing)
if [ ! -f .env.example ]; then
  cat > .env.example <<'ENV'
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
TZ=America/New_York
APP_LOCALE=en-US
FLASK_PORT=5000
FASTAPI_PORT=8000
DJANGO_PORT=8002
ENV
fi

# ----- Flask -----
mkdir -p flask-demo
[ -f flask-demo/requirements.txt ] || printf "flask>=3\ngunicorn>=21\n" > flask-demo/requirements.txt
if [ ! -f flask-demo/app.py ]; then
  cat > flask-demo/app.py <<'PY'
from flask import Flask, jsonify, request
app = Flask(__name__)

@app.get("/")
def index():
    return {"message": "Hello from Flask!"}

@app.get("/echo/<name>")
def echo(name):
    return jsonify(hello=name, q=request.args.get("q"))
PY
fi

# Dockerfile
if [ ! -f flask-demo/Dockerfile ]; then
  cat > flask-demo/Dockerfile <<'DOCKER'
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY . /app/
EXPOSE 5000
CMD ["gunicorn","-w","2","-b","0.0.0.0:5000","app:app"]
DOCKER
fi

# Compose
cat > docker/flask/docker-compose.yml <<'YML'
services:
  web:
    build:
      context: ../../flask-demo
      dockerfile: Dockerfile
    env_file:
      - ../../.env
    ports:
      - "${FLASK_PORT:-5000}:5000"
    # volumes:
    #   - ../../flask-demo:/app
YML

# ----- FastAPI -----
mkdir -p fastapi-demo
[ -f fastapi-demo/requirements.txt ] || printf "fastapi>=0.115\nuvicorn[standard]>=0.30\ngunicorn>=21\npydantic>=2.8\n" > fastapi-demo/requirements.txt
if [ ! -f fastapi-demo/main.py ]; then
  cat > fastapi-demo/main.py <<'PY'
from fastapi import FastAPI
from pydantic import BaseModel
app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI!"}

class Item(BaseModel):
    name: str
    qty: int

@app.post("/items")
def create_item(item: Item):
    return {"ok": True, "item": item}
PY
fi

if [ ! -f fastapi-demo/Dockerfile ]; then
  cat > fastapi-demo/Dockerfile <<'DOCKER'
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY . /app/
EXPOSE 8000
CMD ["gunicorn","-w","2","-k","uvicorn.workers.UvicornWorker","-b","0.0.0.0:8000","main:app"]
DOCKER
fi

cat > docker/fastapi/docker-compose.yml <<'YML'
services:
  web:
    build:
      context: ../../fastapi-demo
      dockerfile: Dockerfile
    env_file:
      - ../../.env
    ports:
      - "${FASTAPI_PORT:-8000}:8000"
    # volumes:
    #   - ../../fastapi-demo:/app
YML

# ----- Django -----
mkdir -p django-demo
[ -f django-demo/requirements.txt ] || printf "django>=5.0\ngunicorn>=21\n" > django-demo/requirements.txt
# We initialize real project at first run; Dockerfile expects manage.py later.
if [ ! -f django-demo/Dockerfile ]; then
  cat > django-demo/Dockerfile <<'DOCKER'
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY . /app/
EXPOSE 8002
CMD ["sh","-c","python manage.py migrate && gunicorn -w 2 -b 0.0.0.0:8002 config.wsgi:application"]
DOCKER
fi

cat > docker/django/docker-compose.yml <<'YML'
services:
  web:
    build:
      context: ../../django-demo
    env_file:
      - ../../.env
    ports:
      - "${DJANGO_PORT:-8002}:8002"
    # volumes:
    #   - ../../django-demo:/app
YML

echo "[ok] docker scaffold ready (docker/* + project Dockerfiles)."

