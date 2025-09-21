import os
import sys
from pathlib import Path

# ---- file contents (exact equivalents of the heredocs) ----
FLASK_APP = """from flask import Flask, jsonify, request
app = Flask(__name__)

@app.get("/")
def index():
    return {"message": "Hello from Flask!"}

@app.get("/echo/<name>")
def echo(name):
    return jsonify(hello=name, q=request.args.get("q"))
"""

FLASK_REQ = """flask>=3,<4
gunicorn>=21
"""

FLASK_LOCK = """flask==3.1.2
gunicorn==23.0.0
"""

FASTAPI_APP = """from fastapi import FastAPI
from pydantic import BaseModel
app = FastAPI()

@app.get('/')
def read_root():
    return {'message': 'Hello from FastAPI!'}

class Item(BaseModel):
    name: str
    qty: int

@app.post('/items')
def create_item(item: Item):
    return {'ok': True, 'item': item}
"""

FASTAPI_REQ = """fastapi>=0.115
uvicorn[standard]>=0.30
gunicorn>=21
pydantic>=2.8
"""

FASTAPI_LOCK = """fastapi==0.115.0
uvicorn[standard]==0.30.6
gunicorn==23.0.0
pydantic==2.8.2
"""

DJANGO_REQ = """django>=5.0,<6
gunicorn>=21
"""

DJANGO_LOCK = """django==5.0.6
gunicorn==23.0.0
"""

DJANGO_README = "Django will be initialized on first run: ./scripts/run.sh django\n"

# ---- helper: write file only if it doesn't exist ----
def write_if_missing(path: Path, content: str):
    if path.is_file():
        print(f"[skip] {path} (exists)")
        return
    with path.open("w", encoding="utf-8", newline="") as f:
        f.write(content)
    print(f"[new] {path}")

def main():
    # cd "$(dirname "$0")/.."
    script_dir = Path(__file__).resolve().parent
    os.chdir(script_dir.parent)

    # usage / args
    if len(sys.argv) < 2:
        print(f"usage: {sys.argv[0]} <flask|fastapi|django>", file=sys.stderr)
        sys.exit(2)

    t = sys.argv[1]

    if t == "flask":
        d = Path("flask-demo")
        d.mkdir(parents=True, exist_ok=True)
        write_if_missing(d / "app.py", FLASK_APP)
        write_if_missing(d / "requirements.txt", FLASK_REQ)
        write_if_missing(d / "requirements-lock.txt", FLASK_LOCK)

    elif t == "fastapi":
        d = Path("fastapi-demo")
        d.mkdir(parents=True, exist_ok=True)
        write_if_missing(d / "main.py", FASTAPI_APP)
        write_if_missing(d / "requirements.txt", FASTAPI_REQ)
        write_if_missing(d / "requirements-lock.txt", FASTAPI_LOCK)

    elif t == "django":
        d = Path("django-demo")
        d.mkdir(parents=True, exist_ok=True)
        write_if_missing(d / "requirements.txt", DJANGO_REQ)
        write_if_missing(d / "requirements-lock.txt", DJANGO_LOCK)
        write_if_missing(d / "README.txt", DJANGO_README)

    else:
        print(f"unknown type: {t}", file=sys.stderr)
        sys.exit(3)

    print(f"Scaffold ready at {d}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)