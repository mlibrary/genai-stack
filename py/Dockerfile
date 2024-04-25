FROM python:3.12

RUN apt-get update && \
  apt-get install -yqq --no-install-recommends \
    cargo && \
  rm -rf \
    /var/lib/apt/lists/* \
    /usr/share/doc \
    /usr/share/locale \
    /usr/share/man

RUN mkdir -p /app

WORKDIR /app

COPY requirements.txt .

CMD tail -f /dev/null
