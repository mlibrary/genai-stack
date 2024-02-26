FROM ruby:3.1

ARG UID
ARG GID
ARG UNAME=app
ENV APP_HOME /app
ENV BUNDLE_PATH /bundle

# Create the group for the user
RUN if [ x"${GID}" != x"" ] ; \
    then groupadd ${UNAME} -g ${GID} -o ; \
    else groupadd ${UNAME} ; \
    fi

#Create the User and assign ${APP_HOME} as its home directory
RUN if [ x"${UID}" != x"" ] ; \
    then  useradd -m -d ${APP_HOME} -u ${UID} -o -g ${UNAME} -s /bin/bash ${UNAME} ; \
    else useradd -m -d ${APP_HOME} -g ${UNAME} -s /bin/bash ${UNAME} ; \
    fi

RUN mkdir -p ${BUNDLE_PATH} ${APP_HOME} && \
    chown -R ${UNAME}:${UNAME} ${BUNDLE_PATH} ${APP_HOME}

WORKDIR $APP_HOME
USER $UNAME
COPY --chown=${UNAME}:${UNAME} Gemfile* ${APP_HOME}/

CMD tail -f /dev/null


