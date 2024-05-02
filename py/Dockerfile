FROM python:3.12

RUN apt-get update && \
  apt-get install -yqq --no-install-recommends \
    cargo vim && \
  rm -rf \
    /var/lib/apt/lists/* \
    /usr/share/doc \
    /usr/share/locale \
    /usr/share/man

RUN mkdir -p /app/cache/pip /app/cache/hf

RUN HF_HOME=/app/cache/hf PIP_CACHE_DIR=/app/cache/pip pip install -U sentence-transformers && \
  rm -rf /app/cache

WORKDIR /app

COPY requirements.txt .

CMD tail -f /dev/null
