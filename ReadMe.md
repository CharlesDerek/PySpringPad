# PySpringPad 🚀  
*A launch pad for Python web apps — scaffold, run, and extend in seconds.*

![Python](https://img.shields.io/badge/python-3.12+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![CI](https://github.com/<your-username>/<your-repo>/actions/workflows/ci.yml/badge.svg)

---

## 🌱 What is PySpringPad?

PySpringPad is a **springboard for Python web development**, inspired by Spring Boot for Java but tailored to Python’s ecosystem.  

It helps you **spin up brand-new Flask, FastAPI, or Django apps in seconds**, then run them locally or in Docker — with foresight for the long haul:

- **Stable builds** (pinned versions, reproducible even in 2035).  
- **Latest builds** (floating versions, beta track to test new releases).  
- **Offline-ready** with cached wheels and tarballs.  
- **Localization-ready** with explicit env vars (`LANG`, `LC_ALL`, `TZ`).  
- **Extensible scaffolding** so each new project benefits from added components (DBs, auth, i18n, CI/CD).

---

## ✨ Features

- 🔨 **Scaffolding**: create Flask/FastAPI/Django demo apps instantly (`make new-*`).  
- ⚡ **Dual-track builds**:  
  - **Stable** → pinned `requirements-lock.txt`, guaranteed reproducibility.  
  - **Latest** → floating `requirements.txt`, always testing newest releases.  
- 📦 **Offline mode**: prepare caches once, then build/run offline with tar + wheels.  
- 🌍 **Localization**: env-driven, future-proof against timezone/locale drift.  
- 🧩 **Extensible**: add once (auth, DB, templates, etc.), reuse everywhere.  
- ✅ **CI-ready**: Dockerfiles + GitHub Actions to validate both stable and latest builds.  

---

## 🚀 Quick start

Clone and enter the repo:

```
git clone git@github.com:CharlesDerek/PySpringPad.git
cd PySpringPad

# copy env template (edit ports/localization as needed)
cp .env.example .env
```

Scaffold projects (if missing):

```
make new-flask
make new-fastapi
make new-django
```

#🖥 Local runs

Stable (pinned versions):

```
make run-flask-stable     # http://127.0.0.1:5001
make run-fastapi-stable   # http://127.0.0.1:8001
make run-django-stable    # http://127.0.0.1:8002
```

Latest (floating versions):

```
make run-flask-latest
make run-fastapi-latest
make run-django-latest
```

#🐳 Docker runs

Stable (from requirements-lock.txt + Dockerfile.stable):

```
make docker-flask-stable
make docker-fastapi-stable
make docker-django-stable
```

Latest (floating `requirements.txt` + `Dockerfile`):

```
make docker-flask-latest
make docker-fastapi-latest
make docker-django-latest
```

#📴 Offline / Air-gapped workflow

Prepare caches once while online:

```
make offline-prepare
```

This saves:

* base Python image (`python:3.12-slim.tar`)
* pinned wheels for each project under `./caches/wheels/*`

Then offline:

```
make offline-use
make docker-flask-offline
make docker-fastapi-offline
make docker-django-offline
```

Fully built images are exported to `./caches/images/built/`.

---

#📂 Project structure

```text
.

pyspringpad/
├── flask-demo/          # Flask scaffold
│   ├── app.py
│   ├── requirements.txt
│   ├── requirements-lock.txt
│   └── Dockerfile(.stable)
├── fastapi-demo/        # FastAPI scaffold
│   ├── main.py
│   ├── requirements.txt
│   ├── requirements-lock.txt
│   └── Dockerfile(.stable)
├── django-demo/         # Django scaffold
│   ├── requirements.txt
│   ├── requirements-lock.txt
│   └── Dockerfile(.stable)
├── docker/              # Compose files for each stack
│   ├── flask/
│   ├── fastapi/
│   └── django/
├── scripts/             # helpers (run, new, offline caching)
├── Makefile             # all entrypoints
├── .env.example         # localization + ports
└── ReadMe.md            # this doc

```

#🗺 Roadmap

    - Starter templates (flask-api, fastapi-rest, django-crm)
    - Auth scaffolding (JWT/OAuth2, Django users)
    - Databases (Postgres, Redis, SQLite dev mode)
    - Background jobs (Celery, RQ, FastAPI workers)
    - Internationalization (Flask-Babel, Django i18n)
    - Deployment configs (AWS, Azure, GCP, Digital Ocean, Docker compose, Kubernetes)
    - Cookiecutter integration for interactive scaffolding
    - PySpring layer: config-driven launch experience, similar to Spring Boot

 🛡 Philosophy

Building PySpringPad with foresight:

Dependencies will drift, break, and deprecate — but pinned requirements-lock.txt + cached wheels make today’s builds reproducible tomorrow.

CI/CD always runs stable + latest to catch issues early.

Localization (LANG, LC_ALL, TZ) ensures predictable behavior across hosts/regions.

Docker images are explicitly versioned, not tied to external defaults.

This repo is not just a demo — it’s a time capsule and launch pad.
Ten years from now, you’ll still be able to scaffold and run a robust Flask/Django/FastAPI app as it worked today.

🤝 Contributing

Contributions are welcome ❤️
    - Use [issues](https://github.com/CharlesDerek/PySpringPad/issues) for bugs/features.
    - PRs should follow [Conventional Commits](https://www.conventionalcommits.org/).
    - Run make clean before committing to avoid .venv clutter.

📜 License

[MIT](https://github.com/CharlesDerek/PySpringPad/blob/main/LICENSE)
 © 2025 Charles Derek