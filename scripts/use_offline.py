import sys
import shutil
import subprocess
from pathlib import Path

PROJECTS = ["flask-demo", "fastapi-demo", "django-demo"]

def run(cmd, cwd=None):
    result = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if result.returncode != 0:
        if result.stderr:
            sys.stderr.write(result.stderr)
        sys.exit(result.returncode)
    return result

def copy_contents(src_dir: Path, dst_dir: Path):
    items = list(src_dir.iterdir())
    if not items:
        raise RuntimeError(f"No wheels found in {src_dir}")
    for item in items:
        dest = dst_dir / item.name
        if item.is_dir():
            shutil.copytree(item, dest)
        else:
            shutil.copy2(item, dest)

def main():
    # cd "$(dirname "$0")/.."
    repo_root = Path(__file__).resolve().parent.parent
    cache = repo_root / "caches"
    images = cache / "images"
    wheels = cache / "wheels"

    print("[*] Loading base image from tar")
    base_tar = images / "python-3.12-slim.tar"
    if not base_tar.exists():
        sys.exit(f"Missing base image tar: {base_tar}")
    run(["docker", "load", "-i", str(base_tar)])

    # Prepare wheels per project
    for p in PROJECTS:
        print(f"[*] Preparing wheels for {p}")
        project_wheels_dst = repo_root / p / "wheels"
        shutil.rmtree(project_wheels_dst, ignore_errors=True)
        project_wheels_dst.mkdir(parents=True, exist_ok=True)

        src = wheels / p
        if not src.exists() or not src.is_dir():
            sys.exit(f"Missing wheels directory for {p}: {src}")
        try:
            copy_contents(src, project_wheels_dst)
        except Exception as e:
            sys.exit(f"Failed copying wheels for {p}: {e}")

    # Build images offline
    print("[*] Building images offline (no network)")
    run([
        "docker", "build", "--network=none",
        "-t", "practice/flask-offline:latest",
        "-f", "./flask-demo/Dockerfile.offline",
        "./flask-demo",
    ], cwd=repo_root)
    run([
        "docker", "build", "--network=none",
        "-t", "practice/fastapi-offline:latest",
        "-f", "./fastapi-demo/Dockerfile.offline",
        "./fastapi-demo",
    ], cwd=repo_root)
    run([
        "docker", "build", "--network=none",
        "-t", "practice/django-offline:latest",
        "-f", "./django-demo/Dockerfile.offline",
        "./django-demo",
    ], cwd=repo_root)

    print("[*] To run offline via compose:")
    print("    docker compose -f docker/flask/compose.offline.yml up --build")
    print("    docker compose -f docker/fastapi/compose.offline.yml up --build")
    print("    docker compose -f docker/django/compose.offline.yml up --build")

    # Export built images to tar
    built_dir = images / "built"
    built_dir.mkdir(parents=True, exist_ok=True)
    run(["docker", "save", "-o", str(built_dir / "flask-offline.tar"), "practice/flask-offline:latest"])
    run(["docker", "save", "-o", str(built_dir / "fastapi-offline.tar"), "practice/fastapi-offline:latest"])
    run(["docker", "save", "-o", str(built_dir / "django-offline.tar"), "practice/django-offline:latest"])

    print(f"[*] Exported built images under {built_dir}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)