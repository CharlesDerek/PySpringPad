#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CACHE="./caches"
IMAGES="$CACHE/images"
WHEELS="$CACHE/wheels"

echo "[*] Loading base image from tar"
docker load -i "$IMAGES/python-3.12-slim.tar"

# Copy wheels into each project before build and build with network disabled
for p in flask-demo fastapi-demo django-demo; do
  echo "[*] Preparing wheels for $p"
  rm -rf "./$p/wheels"
  mkdir -p "./$p/wheels"
  cp -r "$WHEELS/$p/"* "./$p/wheels/"
done

echo "[*] Building images offline (no network)"
docker build --network=none -t practice/flask-offline:latest -f ./flask-demo/Dockerfile.offline ./flask-demo
docker build --network=none -t practice/fastapi-offline:latest -f ./fastapi-demo/Dockerfile.offline ./fastapi-demo
docker build --network=none -t practice/django-offline:latest -f ./django-demo/Dockerfile.offline ./django-demo

echo "[*] To run offline via compose:"
echo "    docker compose -f docker/flask/compose.offline.yml up --build"
echo "    docker compose -f docker/fastapi/compose.offline.yml up --build"
echo "    docker compose -f docker/django/compose.offline.yml up --build"

# Optionally export images to tar for transfer
mkdir -p "$IMAGES/built"
docker save -o "$IMAGES/built/flask-offline.tar" practice/flask-offline:latest
docker save -o "$IMAGES/built/fastapi-offline.tar" practice/fastapi-offline:latest
docker save -o "$IMAGES/built/django-offline.tar" practice/django-offline:latest

echo "[*] Exported built images under $IMAGES/built"
