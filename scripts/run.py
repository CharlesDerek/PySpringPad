import os
import sys
import subprocess
from pathlib import Path

def run(cmd, cwd=None, check=True):
    # Stream output directly to terminal (like bash), optionally check return code
    return subprocess.run(cmd, cwd=cwd, check=check)

def repo_root_dir():
    return Path(__file__).resolve().parent.parent

def choose_reqs(proj: Path, mode: str) -> Path:
    if mode == "--stable":
        return proj / "requirements-lock.txt"
    else:
        return proj / "requirements.txt"

def main():
    # cd to repo root
    os.chdir(repo_root_dir())

    # Args: <flask|fastapi|django> [--stable|--latest]
    if len(sys.argv) < 2:
        print(f"usage: {Path(sys.argv[0]).name} <flask|fastapi|django> [--stable|--latest]", file=sys.stderr)
        sys.exit(2)

    target = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) >= 3 else "--stable"

    if mode not in ("--stable", "--latest"):
        print(f"invalid mode: {mode}", file=sys.stderr)
        sys.exit(3)

    scripts_dir = Path("scripts")

    if target == "flask":
        proj = Path("flask-demo")
        port = "5001"
        entry = "app:app"
        reqs = choose_reqs(proj, mode)

        # Ensure venv exists and is prepared by the existing helper script
        run(["bash", str(scripts_dir / "venv_project.sh"), str(proj)])

        venv_python = proj / ".venv" / "bin" / "python"

        # pip install -r requirements
        run([str(venv_python), "-m", "pip", "install", "-r", str(reqs)])

        # exec: python -m gunicorn --chdir proj -w 2 -b 127.0.0.1:port entry
        os.execvpe(
            str(venv_python),
            [
                str(venv_python),
                "-m", "gunicorn",
                "--chdir", str(proj),
                "-w", "2",
                "-b", f"127.0.0.1:{port}",
                entry,
            ],
            os.environ.copy(),
        )

    elif target == "fastapi":
        proj = Path("fastapi-demo")
        port = "8001"
        entry = "main:app"
        reqs = choose_reqs(proj, mode)

        # Create project if missing, using existing new.sh
        if not proj.is_dir():
            run(["bash", str(scripts_dir / "new.sh"), "fastapi"])

        run(["bash", str(scripts_dir / "venv_project.sh"), str(proj)])

        venv_python = proj / ".venv" / "bin" / "python"

        run([str(venv_python), "-m", "pip", "install", "-r", str(reqs)])

        # exec: python -m gunicorn --chdir proj -w 2 -k uvicorn.workers.UvicornWorker -b 127.0.0.1:port entry
        os.execvpe(
            str(venv_python),
            [
                str(venv_python),
                "-m", "gunicorn",
                "--chdir", str(proj),
                "-w", "2",
                "-k", "uvicorn.workers.UvicornWorker",
                "-b", f"127.0.0.1:{port}",
                entry,
            ],
            os.environ.copy(),
        )

    elif target == "django":
        proj = Path("django-demo")
        port = "8002"
        reqs = choose_reqs(proj, mode)

        # Create project if missing
        if not proj.is_dir():
            run(["bash", str(scripts_dir / "new.sh"), "django"])

        run(["bash", str(scripts_dir / "venv_project.sh"), str(proj)])

        venv_dir = proj / ".venv" / "bin"
        venv_python = venv_dir / "python"
        venv_django_admin = venv_dir / "django-admin"
        venv_gunicorn = venv_dir / "gunicorn"

        run([str(venv_python), "-m", "pip", "install", "-r", str(reqs)])

        # If manage.py missing, start a Django project named "config" in proj dir
        manage_py = proj / "manage.py"
        if not manage_py.is_file():
            run([str(venv_django_admin), "startproject", "config", "."], cwd=str(proj))

        # Run migrations, ignore failures (|| true)
        run([str(venv_python), "manage.py", "migrate"], cwd=str(proj), check=False)

        # exec gunicorn
        os.execvpe(
            str(venv_gunicorn),
            [
                str(venv_gunicorn),
                "--chdir", str(proj),
                "-w", "2",
                "-b", f"127.0.0.1:{port}",
                "config.wsgi:application",
            ],
            os.environ.copy(),
        )

    else:
        print(f"unknown target: {target}", file=sys.stderr)
        sys.exit(3)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)