#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ $# -lt 1 ]; then
  echo "usage: $0 <flask|fastapi|django>" >&2
  exit 2
fi

t="$1"

# ---- helper: write file only if it doesn't exist ----
write_if_missing () {
  # $1 = path, $2 = content
  if [ ! -f "$1" ]; then
    printf "%s" "$2" > "$1"
    echo "[new] $1"
  else
    echo "[skip] $1 (exists)"
  fi
}

case "$t" in
  flask)
    d="flask-demo"; mkdir -p "$d"

    # app
    write_if_missing "$d/app.py" "$(cat <<'PY'
from flask import Flask, jsonify, request
app = Flask(__name__)

@app.get("/")
def index():
    return {"message": "Hello from Flask!"}

@app.get("/echo/<name>")
def echo(name):
    return jsonify(hello=name, q=request.args.get("q"))
PY
)"

    # floating (beta/latest)
    write_if_missing "$d/requirements.txt" "$(cat <<'REQ'
flask>=3,<4
gunicorn>=21
REQ
)"

    # pinned (stable/reproducible) — update pins as you curate them over time
    write_if_missing "$d/requirements-lock.txt" "$(cat <<'LOCK'
flask==3.1.2
gunicorn==23.0.0
LOCK
)"
    ;;

  fastapi)
    d="fastapi-demo"; mkdir -p "$d"

    # app
    write_if_missing "$d/main.py" "$(cat <<'PY'
from fastapi import FastAPI
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
PY
)"

    # floating (beta/latest)
    write_if_missing "$d/requirements.txt" "$(cat <<'REQ'
fastapi>=0.115
uvicorn[standard]>=0.30
gunicorn>=21
pydantic>=2.8
REQ
)"

    # pinned (stable/reproducible)
    write_if_missing "$d/requirements-lock.txt" "$(cat <<'LOCK'
fastapi==0.115.0
uvicorn[standard]==0.30.6
gunicorn==23.0.0
pydantic==2.8.2
LOCK
)"
    ;;

  django)
    d="django-demo"; mkdir -p "$d"

    # floating (beta/latest)
    write_if_missing "$d/requirements.txt" "$(cat <<'REQ'
django>=5.0,<6
gunicorn>=21
REQ
)"

    # pinned (stable/reproducible)
    write_if_missing "$d/requirements-lock.txt" "$(cat <<'LOCK'
django==5.0.6
gunicorn==23.0.0
LOCK
)"

    write_if_missing "$d/README.txt" "Django will be initialized on first run: ./scripts/run.sh django
"
    ;;

  *)
    echo "unknown type: $t" >&2
    exit 3
    ;;
esac

echo "Scaffold ready at $d"
