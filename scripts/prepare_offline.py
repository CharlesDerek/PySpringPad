import os
import sys
import subprocess
from pathlib import Path

PROJECTS = ["flask-demo", "fastapi-demo", "django-demo"]
DEFAULT_BASE_IMAGE = "python:3.12-slim"

def run(cmd, cwd=None):
    subprocess.run(cmd, cwd=cwd, check=True)

def venv_python_path(venv_dir: Path) -> Path:
    # Cross-platform path to the venv's python
    if os.name == "nt":
        return venv_dir / "Scripts" / "python.exe"
    return venv_dir / "bin" / "python"

def main():
    # cd "$(dirname "$0")/.."
    repo_root = Path(__file__).resolve().parent.parent
    os.chdir(repo_root)

    cache = Path("./caches")
    images = cache / "images"
    wheels = cache / "wheels"

    # mkdir -p "$IMAGES" "$WHEELS"/{flask-demo,fastapi-demo,django-demo}
    images.mkdir(parents=True, exist_ok=True)
    wheels.mkdir(parents=True, exist_ok=True)
    for p in PROJECTS:
        (wheels / p).mkdir(parents=True, exist_ok=True)

    # Docker pull/save
    base = os.getenv("BASE_IMAGE", DEFAULT_BASE_IMAGE)
    print(f"[*] Pulling base: {base}")
    run(["docker", "pull", base])
    tar_name = base.replace("/", "-").replace(":", "-") + ".tar"
    run(["docker", "save", "-o", str(images / tar_name), base])

    # Create temp venv for wheel downloads
    tmpvenv = cache / ".venv"
    run([sys.executable, "-m", "venv", str(tmpvenv)])
    vpy = venv_python_path(tmpvenv)

    # Upgrade pip
    run([str(vpy), "-m", "pip", "install", "--upgrade", "pip"])

    # Download wheels per project
    for p in PROJECTS:
        print(f"[*] Downloading wheels for {p}")
        req = repo_root / p / "requirements-lock.txt"
        dest = wheels / p
        dest.mkdir(parents=True, exist_ok=True)
        run([str(vpy), "-m", "pip", "download", "-d", str(dest), "-r", str(req)])

    print(f"[*] Cache prepared under {cache}")

if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)
    except KeyboardInterrupt:
        sys.exit(130)