"""Shared helpers for MySQL backup / restore scripts."""

from __future__ import annotations

import os
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from app.config import get_settings

BACKEND_ROOT = Path(__file__).resolve().parent.parent
BACKUPS_DIR = BACKEND_ROOT / "backups"
LATEST_BACKUP_NAME = "latest.sql"


def ensure_backups_dir() -> Path:
    BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
    return BACKUPS_DIR


def find_mysql_tool(tool: str) -> str:
    candidates = [
        BACKEND_ROOT / "bin" / f"{tool}.exe",
        Path(os.environ.get("MYSQL_HOME", "")) / "bin" / f"{tool}.exe",
        Path(r"C:\Program Files\MySQL\MySQL Server 8.4\bin") / f"{tool}.exe",
        Path(r"C:\Program Files\MySQL\MySQL Server 8.0\bin") / f"{tool}.exe",
        Path(r"C:\Program Files\MySQL\MySQL Server 5.7\bin") / f"{tool}.exe",
    ]
    for candidate in candidates:
        if candidate and candidate.exists():
            return str(candidate)
    found = shutil.which(tool)
    if found:
        return found
    raise FileNotFoundError(
        f"Cannot find `{tool}`. Install MySQL client tools or add them to PATH."
    )


def mysql_connection_args() -> list[str]:
    settings = get_settings()
    args = [
        f"--host={settings.mysql_host}",
        f"--port={settings.mysql_port}",
        f"--user={settings.mysql_user}",
    ]
    if settings.mysql_password:
        args.append(f"--password={settings.mysql_password}")
    else:
        args.append("--password=")
    return args


def timestamped_backup_path() -> Path:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    settings = get_settings()
    return ensure_backups_dir() / f"{settings.mysql_database}_{stamp}.sql"


def update_latest_copy(source: Path) -> Path:
    latest = ensure_backups_dir() / LATEST_BACKUP_NAME
    latest.write_bytes(source.read_bytes())
    return latest


def list_backup_files() -> list[Path]:
    ensure_backups_dir()
    files = sorted(
        (
            path
            for path in BACKUPS_DIR.glob("*.sql")
            if path.name != LATEST_BACKUP_NAME
        ),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    return files


def resolve_import_file(file_arg: str | None) -> Path:
    if file_arg:
        path = Path(file_arg)
        if not path.is_absolute():
            path = BACKEND_ROOT / path
        if not path.exists():
            raise FileNotFoundError(f"Backup file not found: {path}")
        return path

    latest = BACKUPS_DIR / LATEST_BACKUP_NAME
    if latest.exists():
        return latest

    backups = list_backup_files()
    if not backups:
        raise FileNotFoundError(
            f"No backup files in {BACKUPS_DIR}. Run export_db.py first."
        )
    return backups[0]


def run_command(command: list[str], *, input_file: Path | None = None) -> None:
    kwargs: dict = {"check": True}
    if input_file is not None:
        with input_file.open("rb") as handle:
            subprocess.run(command, stdin=handle, **kwargs)
    else:
        subprocess.run(command, **kwargs)
