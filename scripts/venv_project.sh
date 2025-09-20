#!/usr/bin/env bash
set -euo pipefail
if [ $# -ne 1 ]; then
  echo "usage: $0 <project_dir>" >&2
  exit 2
fi
proj="$1"
cd "$proj"
if [ ! -x ./.venv/bin/python ]; then
  python3 -m venv .venv
fi
./.venv/bin/python -m pip install --upgrade pip wheel setuptools
