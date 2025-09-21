# -------- Settings --------
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
        clean \
        clean-full \
		stack-list \

# Optional: override by `make DOCKER=podman COMPOSE="compose"`
DOCKER ?= docker
COMPOSE ?= compose

# Scripts location and Python interpreter
SCRIPTS := ./scripts
PYTHON ?= python3

# Define the stacks you support
STACKS := flask fastapi django
STACKS_PRETTY := Flask FastAPI Django


# Auto-detect script extension/runner once (prefers executable, then .py, then .sh)
# Example shown with "new"; assumes all scripts share the same style.
ifneq ($(wildcard $(SCRIPTS)/new),)
  SCRIPT_EXT :=
  SCRIPT_RUNNER :=
else ifneq ($(wildcard $(SCRIPTS)/new.py),)
  SCRIPT_EXT := .py
  SCRIPT_RUNNER := $(PYTHON)
else
  SCRIPT_EXT := .sh
  SCRIPT_RUNNER :=
endif

# Helper macro to run a script: $(call runscript,script_name,extra_args...)
runscript = $(SCRIPT_RUNNER) $(SCRIPTS)/$1$(SCRIPT_EXT) $(2)

help:
	@printf "Targets:\n"
	@printf "  %-40s - %s\n" "clean" "remove per-project venvs"
	@printf "  %-40s - %s\n" "clean-full" "remove per-project full contents (starting from scratch)"
	@printf "  %-40s - %s\n" "docker-init" "scaffold docker/* and Dockerfiles if missing"
	@printf "  %-40s - %s\n" "docker-<stack>" "build+run with Compose (uses .env if present)"
	@printf "  %-40s - %s\n" "docker-<stack>-stable" "compose using Dockerfile.stable (pinned)"
	@printf "  %-40s - %s\n" "docker-<stack>-latest" "compose using Dockerfile (floating)"
	@printf "  %-40s - %s\n" "docker-<stack>-offline" "build+run using offline Dockerfiles"
	@printf "  %-40s - %s\n" "new-<stack>" "scaffold project folders (if missing)"
	@printf "  %-40s - %s\n" "offline-prepare" "cache base image and wheels (online)"
	@printf "  %-40s - %s\n" "offline-use" "load base tar, build images offline, export tars"
	@printf "  %-40s - %s\n" "run-<stack>-[stable(default)|latest]" "run via local venv + gunicorn"
	@printf "  %-40s - %s\n" "stack-list" "list existing project tech stacks"

# ---------- Stacks scaffolding ----------
new-flask:
	$(call runscript,new,flask)

new-fastapi:
	$(call runscript,new,fastapi)

new-django:
	$(call runscript,new,django)

# ---------- Local venv runners ----------
# Legacy aliases (default to stable for reproducibility)
run-flask: run-flask-stable
run-fastapi: run-fastapi-stable
run-django: run-django-stable

# Stable (pinned requirements-lock.txt)
run-flask-stable:
	$(call runscript,run,flask --stable)
run-fastapi-stable:
	$(call runscript,run,fastapi --stable)
run-django-stable:
	$(call runscript,run,django --stable)

# Latest (floating requirements.txt)
run-flask-latest:
	$(call runscript,run,flask --latest)
run-fastapi-latest:
	$(call runscript,run,fastapi --latest)
run-django-latest:
	$(call runscript,run,django --latest)

# ---------- Docker scaffolding (idempotent) ----------
docker-init:
	@$(call runscript,docker_scaffold)
	@# Create .env from example if missing (for localization/ports)
	@if [ ! -f .env ] && [ -f .env.example ]; then cp .env.example .env; fi

# ---------- Online Compose (LATEST = floating) ----------
docker-flask: docker-init
	cd docker/flask && $(DOCKER) $(COMPOSE) -f docker-compose.yml up --build
docker-fastapi: docker-init
	cd docker/fastapi && $(DOCKER) $(COMPOSE) -f docker-compose.yml up --build
docker-django: docker-init
	cd docker/django && $(DOCKER) $(COMPOSE) -f docker-compose.yml up --build

# ---------- Online Compose (STABLE = pinned) ----------
docker-flask-stable: docker-init
	cd docker/flask && $(DOCKER) $(COMPOSE) -f docker-compose.stable.yml up --build
docker-fastapi-stable: docker-init
	cd docker/fastapi && $(DOCKER) $(COMPOSE) -f docker-compose.stable.yml up --build
docker-django-stable: docker-init
	cd docker/django && $(DOCKER) $(COMPOSE) -f docker-compose.stable.yml up --build

# ---------- Online Compose (explicit LATEST shortcuts) ----------
docker-flask-latest: docker-flask
docker-fastapi-latest: docker-fastapi
docker-django-latest: docker-django

# ---------- Offline Compose (expects your existing offline artifacts) ----------
docker-flask-offline: docker-init
	cd docker/flask && $(DOCKER) $(COMPOSE) -f docker-compose.offline.yml up --build
docker-fastapi-offline: docker-init
	cd docker/fastapi && $(DOCKER) $(COMPOSE) -f docker-compose.offline.yml up --build
docker-django-offline: docker-init
	cd docker/django && $(DOCKER) $(COMPOSE) -f docker-compose.offline.yml up --build

# ---------- Offline caching/build ----------
offline-prepare:
	$(call runscript,prepare_offline)

offline-use:
	$(call runscript,use_offline)

# ---------- Cleanup ----------
clean: 
	rm -rf flask-demo/.venv fastapi-demo/.venv django-demo/.venv

clean-full:
	rm -rf flask-demo/* fastapi-demo/* django-demo/*


stack-list:
	@printf "Available project stacks (%d):\n" $(words $(STACKS))
	@printf "  - %s\n" $(STACKS)