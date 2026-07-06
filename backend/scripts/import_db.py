"""Import MySQL database from backend/backups/ (方案 D)."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pymysql  # noqa: E402

from app.config import get_settings  # noqa: E402
from scripts.db_backup_utils import (  # noqa: E402
    find_mysql_tool,
    mysql_connection_args,
    resolve_import_file,
    run_command,
)


def ensure_database_exists() -> None:
    settings = get_settings()
    connection = pymysql.connect(
        host=settings.mysql_host,
        port=settings.mysql_port,
        user=settings.mysql_user,
        password=settings.mysql_password,
        charset="utf8mb4",
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                f"CREATE DATABASE IF NOT EXISTS `{settings.mysql_database}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
        connection.commit()
    finally:
        connection.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Car Washing MySQL backup")
    parser.add_argument(
        "--file",
        "-f",
        help="Backup .sql path (default: backups/latest.sql or newest backup)",
    )
    args = parser.parse_args()

    settings = get_settings()
    backup = resolve_import_file(args.file)
    mysql = find_mysql_tool("mysql")

    print(f"Importing from: {backup}")
    print(f"Target database: {settings.mysql_database}")
    ensure_database_exists()

    command = [mysql, *mysql_connection_args()]
    run_command(command, input_file=backup)

    print("Import completed.")
    print("Restart the backend if it is already running:")
    print("  python -m uvicorn app.main:app --host 0.0.0.0 --port 8001")


if __name__ == "__main__":
    main()
