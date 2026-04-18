#!/bin/sh
set -e

echo "Running migrations and seeding database..."
python manage.py

echo "Starting application..."
exec gunicorn -w 4 -b 0.0.0.0:5001 "run:app"
