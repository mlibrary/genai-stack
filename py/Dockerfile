FROM python:3.13.0a6

RUN apt-get update && \
  apt-get install -yqq --no-install-recommends \
    cargo && \
  pip install -U sentence-transformers \
  rm -rf \
    /var/lib/apt/lists/* \
    /usr/share/doc \
    /usr/share/locale \
    /usr/share/man

RUN mkdir -p /app

WORKDIR /app

CMD tail -f /dev/null
