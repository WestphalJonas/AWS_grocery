#!/bin/sh
set -e

echo "Initializing database..."
python << 'EOF'
import os
import time
import psycopg2
from app import create_app, db

# Wait for DB
POSTGRES_URI = os.getenv("POSTGRES_URI")
print("⏳ Waiting for database to be ready...")
while True:
    try:
        conn = psycopg2.connect(POSTGRES_URI)
        conn.close()
        print("✅ Database is ready!")
        break
    except psycopg2.OperationalError:
        print("⚠️ Database not ready yet. Retrying in 3 seconds...")
        time.sleep(3)

# Create tables
app = create_app()
with app.app_context():
    db.create_all()
    print("✅ Database tables created/verified")

# Seed database
sql_file = "app/sqlite_dump_clean.sql"
if os.path.exists(sql_file):
    print("📂 Seeding database...")
    with app.app_context():
        conn = db.engine.raw_connection()
        cursor = conn.cursor()
        with open(sql_file, "r", encoding="utf-8") as f:
            sql_commands = [cmd.strip() for cmd in f.read().split(";") if cmd.strip()]
        for command in sql_commands:
            if "INSERT INTO products" in command:
                try:
                    cursor.execute(command)
                except Exception:
                    conn.rollback()
        conn.commit()
        for command in sql_commands:
            if "INSERT INTO products" not in command:
                try:
                    cursor.execute(command)
                except Exception:
                    conn.rollback()
        conn.commit()
        cursor.close()
        conn.close()
    print("✅ Database seeded")
EOF

echo "Starting application..."
exec gunicorn -w 4 -b 0.0.0.0:5001 "run:app"
