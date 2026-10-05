#!/usr/bin/env bash
# Exit on error
set -o errexit

pip install --upgrade pip
pip install -r requirements.txt

python manage.py collectstatic --no-input
python manage.py migrate

# Seed 13 categories and 1,000 realistic posts per category (13,000 posts)
python manage.py seed_bulk --count 1000
