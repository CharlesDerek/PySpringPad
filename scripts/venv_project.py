import argparse
import os
import sys
import subprocess
from pathlib import Path
import venv

def venv_python_path(venv_dir: Path) -> Path:
    # Cross-platform: bin/python on POSIX, Scripts/python.exe on Windows
    if os.name == "nt":
        return venv_dir / "Scripts" / "python.exe"
    else:
        return venv_dir / "bin" / "python"

def ensure_venv(venv_dir: Path) -> Path:
    py = venv_python_path(venv_dir)
    if not (py.exists() and os.access(py, os.X_OK)):
        # Equivalent to: python3 -m venv .venv (with pip included)
        venv.EnvBuilder(with_pip=True).create(venv_dir)
    return py

def main() -> int:
    parser = argparse.ArgumentParser(
        usage="%(prog)s <project_dir>",
        description="Create <project_dir>/.venv if missing and upgrade pip, wheel, setuptools."
    )
    parser.add_argument("project_dir")
    args = parser.parse_args()

    proj = Path(args.project_dir)
    try:
        os.chdir(proj)
    except OSError as e:
        print(f"Error: cannot cd into {proj}: {e}", file=sys.stderr)
        return 1

    py = ensure_venv(Path(".venv"))

    # Upgrade pip tooling inside the venv
    result = subprocess.run([str(py), "-m", "pip", "install", "--upgrade", "pip", "wheel", "setuptools"])
    return result.returncode

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
