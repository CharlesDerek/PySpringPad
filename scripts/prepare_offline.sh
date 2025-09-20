#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CACHE="./caches"
IMAGES="$CACHE/images"
WHEELS="$CACHE/wheels"
mkdir -p "$IMAGES" "$WHEELS"/{flask-demo,fastapi-demo,django-demo}

BASE="python:3.12-slim"
echo "[*] Pulling base: $BASE"
docker pull "$BASE"
docker save -o "$IMAGES/python-3.12-slim.tar" "$BASE"

# Create a temp venv for wheel downloads
TMPVENV="$CACHE/.venv"
python3 -m venv "$TMPVENV"
source "$TMPVENV/bin/activate"
python -m pip install --upgrade pip

for p in flask-demo fastapi-demo django-demo; do
  echo "[*] Downloading wheels for $p"
  pip download -d "$WHEELS/$p" -r "./$p/requirements-lock.txt"
done
deactivate

echo "[*] Cache prepared under $CACHE"
