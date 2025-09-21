import sys, os
from pathlib import Path
from textwrap import dedent

def write_if_missing(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(content, encoding="utf-8")

def write_always(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")

def main():
    # cd to repo root (one level above scripts/)
    root = Path(__file__).resolve().parent.parent
    os.chdir(root)

    # ensure base dirs
    (root / "docker" / "flask").mkdir(parents=True, exist_ok=True)
    (root / "docker" / "fastapi").mkdir(parents=True, exist_ok=True)
    (root / "docker" / "django").mkdir(parents=True, exist_ok=True)

    # .env.example (only if missing)
    env_example = dedent("""\
    LANG=en_US.UTF-8
    LC_ALL=en_US.UTF-8
    TZ=America/New_York
    APP_LOCALE=en-US
    FLASK_PORT=5000
    FASTAPI_PORT=8000
    DJANGO_PORT=8002
    """)
    write_if_missing(root / ".env.example", env_example)

    # ----- Flask -----
    flask_dir = root / "flask-demo"
    flask_dir.mkdir(parents=True, exist_ok=True)

    write_if_missing(flask_dir / "requirements.txt", "flask>=3\ngunicorn>=21\n")

    flask_app_py = dedent("""\
    from flask import Flask, jsonify, request
    app = Flask(__name__)

    @app.get("/")
    def index():
        return {"message": "Hello from Flask!"}

    @app.get("/echo/<name>")
    def echo(name):
        return jsonify(hello=name, q=request.args.get("q"))
    """)
    write_if_missing(flask_dir / "app.py", flask_app_py)

    flask_dockerfile = dedent("""\
    FROM python:3.12-slim
    ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
    WORKDIR /app
    COPY requirements.txt /app/requirements.txt
    RUN pip install --no-cache-dir -r /app/requirements.txt
    COPY . /app/
    EXPOSE 5000
    CMD ["gunicorn","-w","2","-b","0.0.0.0:5000","app:app"]
    """)
    write_if_missing(flask_dir / "Dockerfile", flask_dockerfile)

    flask_compose = dedent("""\
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
    """)
    write_always(root / "docker" / "flask" / "docker-compose.yml", flask_compose)

    # ----- FastAPI -----
    fastapi_dir = root / "fastapi-demo"
    fastapi_dir.mkdir(parents=True, exist_ok=True)

    write_if_missing(fastapi_dir / "requirements.txt",
                     "fastapi>=0.115\nuvicorn[standard]>=0.30\ngunicorn>=21\npydantic>=2.8\n")

    fastapi_main_py = dedent("""\
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
    """)
    write_if_missing(fastapi_dir / "main.py", fastapi_main_py)

    fastapi_dockerfile = dedent("""\
    FROM python:3.12-slim
    ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
    WORKDIR /app
    COPY requirements.txt /app/requirements.txt
    RUN pip install --no-cache-dir -r /app/requirements.txt
    COPY . /app/
    EXPOSE 8000
    CMD ["gunicorn","-w","2","-k","uvicorn.workers.UvicornWorker","-b","0.0.0.0:8000","main:app"]
    """)
    write_if_missing(fastapi_dir / "Dockerfile", fastapi_dockerfile)

    fastapi_compose = dedent("""\
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
    """)
    write_always(root / "docker" / "fastapi" / "docker-compose.yml", fastapi_compose)

    # ----- Django -----
    django_dir = root / "django-demo"
    django_dir.mkdir(parents=True, exist_ok=True)

    write_if_missing(django_dir / "requirements.txt", "django>=5.0\ngunicorn>=21\n")

    django_dockerfile = dedent("""\
    FROM python:3.12-slim
    ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
    WORKDIR /app
    COPY requirements.txt /app/requirements.txt
    RUN pip install --no-cache-dir -r /app/requirements.txt
    COPY . /app/
    EXPOSE 8002
    CMD ["sh","-c","python manage.py migrate && gunicorn -w 2 -b 0.0.0.0:8002 config.wsgi:application"]
    """)
    write_if_missing(django_dir / "Dockerfile", django_dockerfile)

    django_compose = dedent("""\
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
    """)
    write_always(root / "docker" / "django" / "docker-compose.yml", django_compose)

    print("[ok] docker scaffold ready (docker/* + project Dockerfiles).")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)