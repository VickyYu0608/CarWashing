import pymysql
from sqlalchemy import create_engine, text

from app.config import get_settings


def main() -> None:
    settings = get_settings()
    print(f"MySQL: {settings.mysql_host}:{settings.mysql_port}/{settings.mysql_database}")
    engine = create_engine(settings.sqlalchemy_database_url, pool_pre_ping=True)
    with engine.connect() as conn:
        tables = [
            row[0]
            for row in conn.execute(
                text(
                    "SELECT table_name FROM information_schema.tables "
                    "WHERE table_schema = :schema ORDER BY table_name"
                ),
                {"schema": settings.mysql_database},
            )
        ]
        print("Tables:")
        for table in tables:
            count = conn.execute(text(f"SELECT COUNT(*) FROM `{table}`")).scalar()
            print(f"  - {table}: {count} rows")


if __name__ == "__main__":
    main()
