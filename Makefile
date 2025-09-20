.PHONY: help \
        new-flask new-fastapi new-django \
        run-flask run-fastapi run-django \
        run-flask-stable run-flask-latest \
        run-fastapi-stable run-fastapi-latest \
        run-django-stable run-django-latest \
        docker-init \
        docker-flask docker-fastapi docker-django \
        docker-flask-stable docker-flask-latest \
        docker-fastapi-stable docker-fastapi-latest \
        docker-django-stable docker-django-latest \
        docker-flask-offline docker-fastapi-offline docker-django-offline \
        offline-prepare offline-use \
        clean

# Optional: override by `make DOCKER=podman COMPOSE="compose"`
DOCKER ?= docker
COMPOSE ?= compose

help:
	@echo "Targets:"
	@echo "  new-flask/new-fastapi/new-django  - scaffold project folders (if missing)"
	@echo "  run-<stack>[-stable|-latest]      - run via local venv + gunicorn"
	@echo "  docker-init                       - scaffold docker/* and Dockerfiles if missing"
	@echo "  docker-<stack>                    - build+run with Compose (uses .env if present)"
	@echo "  docker-<stack>-stable             - compose using Dockerfile.stable (pinned)"
	@echo "  docker-<stack>-latest             - compose using Dockerfile (floating)"
	@echo "  docker-<stack>-offline            - build+run using offline Dockerfiles"
	@echo "  offline-prepare                   - cache base image and wheels (online)"
	@echo "  offline-use                       - load base tar, build images offline, export tars"
	@echo "  clean                              - remove per-project venvs"

# ---------- App scaffolding ----------
new-flask:
	./scripts/new.sh flask

new-fastapi:
	./scripts/new.sh fastapi

new-django:
	./scripts/new.sh django

# ---------- Local venv runners ----------
# Legacy aliases (default to stable for reproducibility)
run-flask: run-flask-stable
run-fastapi: run-fastapi-stable
run-django: run-django-stable

# Stable (pinned requirements-lock.txt)
run-flask-stable:
	./scripts/run.sh flask --stable
run-fastapi-stable:
	./scripts/run.sh fastapi --stable
run-django-stable:
	./scripts/run.sh django --stable

# Latest (floating requirements.txt)
run-flask-latest:
	./scripts/run.sh flask --latest
run-fastapi-latest:
	./scripts/run.sh fastapi --latest
run-django-latest:
	./scripts/run.sh django --latest

# ---------- Docker scaffolding (idempotent) ----------
docker-init:
	@./scripts/docker_scaffold.sh
	@# Create .env from example if missing (for localization/ports)
	@if [ ! -f .env ] && [ -f .env.example ]; then cp .env.example .env; fi

# ---------- Online Compose (LATEST = floating) ----------
docker-flask: docker-init
	cd docker/flask && $(DOCKER) $(COMPOSE) -f compose.yml up --build
docker-fastapi: docker-init
	cd docker/fastapi && $(DOCKER) $(COMPOSE) -f compose.yml up --build
docker-django: docker-init
	cd docker/django && $(DOCKER) $(COMPOSE) -f compose.yml up --build

# ---------- Online Compose (STABLE = pinned) ----------
docker-flask-stable: docker-init
	cd docker/flask && $(DOCKER) $(COMPOSE) -f compose.stable.yml up --build
docker-fastapi-stable: docker-init
	cd docker/fastapi && $(DOCKER) $(COMPOSE) -f compose.stable.yml up --build
docker-django-stable: docker-init
	cd docker/django && $(DOCKER) $(COMPOSE) -f compose.stable.yml up --build

# ---------- Online Compose (explicit LATEST shortcuts) ----------
docker-flask-latest: docker-flask
docker-fastapi-latest: docker-fastapi
docker-django-latest: docker-django

# ---------- Offline Compose (expects your existing offline artifacts) ----------
docker-flask-offline: docker-init
	cd docker/flask && $(DOCKER) $(COMPOSE) -f compose.offline.yml up --build
docker-fastapi-offline: docker-init
	cd docker/fastapi && $(DOCKER) $(COMPOSE) -f compose.offline.yml up --build
docker-django-offline: docker-init
	cd docker/django && $(DOCKER) $(COMPOSE) -f compose.offline.yml up --build

# ---------- Offline caching/build ----------
offline-prepare:
	./scripts/prepare_offline.sh

offline-use:
	./scripts/use_offline.sh

# ---------- Cleanup ----------
clean:
	rm -rf flask-demo/.venv fastapi-demo/.venv django-demo/.venv
