#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."  # repo root

if [ $# -lt 1 ]; then
  echo "usage: $0 <flask|fastapi|django> [--stable|--latest]" >&2
  exit 2
fi

target="$1"
mode="${2:---stable}"   # default = stable
[ "$mode" = "--stable" ] || [ "$mode" = "--latest" ] || { echo "invalid mode: $mode"; exit 3; }

choose_reqs () {
  proj="$1"
  if [ "$mode" = "--stable" ]; then
    echo "$proj/requirements-lock.txt"
  else
    echo "$proj/requirements.txt"
  fi
}

if [ "$target" = "flask" ]; then
  proj="flask-demo"; port="5001"; entry="app:app"
  reqs=$(choose_reqs "$proj")
  ./scripts/venv_project.sh "$proj"
  ./"$proj"/.venv/bin/pip install -r "$reqs"
  exec ./"$proj"/.venv/bin/python -m gunicorn --chdir "$proj" -w 2 -b 127.0.0.1:"$port" "$entry"

elif [ "$target" = "fastapi" ]; then
  proj="fastapi-demo"; port="8001"; entry="main:app"
  reqs=$(choose_reqs "$proj")
  [ -d "$proj" ] || ./scripts/new.sh fastapi
  ./scripts/venv_project.sh "$proj"
  ./"$proj"/.venv/bin/pip install -r "$reqs"
  exec ./"$proj"/.venv/bin/python -m gunicorn --chdir "$proj" -w 2 -k uvicorn.workers.UvicornWorker -b 127.0.0.1:"$port" "$entry"

elif [ "$target" = "django" ]; then
  proj="django-demo"; port="8002"
  reqs=$(choose_reqs "$proj")
  [ -d "$proj" ] || ./scripts/new.sh django
  ./scripts/venv_project.sh "$proj"
  ./"$proj"/.venv/bin/pip install -r "$reqs"
  if [ ! -f "$proj/manage.py" ]; then
    ( cd "$proj" && ./.venv/bin/django-admin startproject config . )
  fi
  ( cd "$proj" && ./.venv/bin/python manage.py migrate || true )
  exec ./"$proj"/.venv/bin/gunicorn --chdir "$proj" -w 2 -b 127.0.0.1:"$port" config.wsgi:application

else
  echo "unknown target: $target" >&2
  exit 3
fi
