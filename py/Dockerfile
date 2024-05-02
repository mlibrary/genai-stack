FROM python:3.12

RUN apt-get update && \
  apt-get install -yqq --no-install-recommends \
    cargo vim && \
  rm -rf \
    /var/lib/apt/lists/* \
    /usr/share/doc \
    /usr/share/locale \
    /usr/share/man

RUN mkdir -p /app

WORKDIR /app

ARG UNAME=app
ARG UID
ARG GID
ENV APP_HOME /app

#Create the group for the user
RUN if [ x"${GID}" != x"" ] ; \
    then groupadd ${UNAME} -g ${GID} -o ; \
    else groupadd ${UNAME} ; \
    fi

#Create the User and assign ${APP_HOME} as its home directory
RUN if [ x"${UID}" != x"" ] ; \
    then  useradd -m -d ${APP_HOME} -u ${UID} -o -g ${UNAME} -s /bin/bash ${UNAME} ; \
    else useradd -m -d ${APP_HOME} -g ${UNAME} -s /bin/bash ${UNAME} ; \
    fi

COPY requirements.txt .

CMD tail -f /dev/null
