"""Export MySQL database to backend/backups/ (方案 D)."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scripts.db_backup_utils import (  # noqa: E402
    find_mysql_tool,
    mysql_connection_args,
    timestamped_backup_path,
    update_latest_copy,
)
from app.config import get_settings  # noqa: E402


def main() -> None:
    settings = get_settings()
    mysqldump = find_mysql_tool("mysqldump")
    output = timestamped_backup_path()

    command = [
        mysqldump,
        *mysql_connection_args(),
        "--single-transaction",
        "--routines",
        "--triggers",
        "--set-gtid-purged=OFF",
        "--databases",
        settings.mysql_database,
    ]

    print(f"Exporting `{settings.mysql_database}` ...")
    with output.open("wb") as handle:
        import subprocess

        subprocess.run(command, check=True, stdout=handle)

    latest = update_latest_copy(output)
    size_kb = output.stat().st_size / 1024
    print(f"Saved: {output}")
    print(f"Latest copy: {latest}")
    print(f"Size: {size_kb:.1f} KB")
    print()
    print("换电脑时：复制整个 backend/backups/ 文件夹到新电脑，然后运行:")
    print("  python scripts/import_db.py")


if __name__ == "__main__":
    main()
