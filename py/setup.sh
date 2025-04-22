#!/bin/bash

if [ ! -e /app/venv/bin/activate ] ; then
  mkdir -p /app/venv/tmp /app/venv/cache/pip /app/lib/cache/hf
  python -m venv /app/venv
  source /app/venv/bin/activate
  pip install -r requirements.txt
  python setup.py
fi
