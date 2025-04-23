#!/bin/bash

if [ ! -e /app/venv/bin/activate ] ; then
  mkdir -p /app/venv/tmp /app/venv/cache/pip /app/venv/lib/cache/hf
  python -m venv /app/venv
  source /app/venv/bin/activate
  pip install -r requirements.txt
  python setup1.py
  python setup2.py
  python setup3.py
fi
