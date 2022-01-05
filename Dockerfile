# ------------------------------------------------------------------------------------
# Keycloak image built for aarch64 and also adds a custom provider for resolving
# themes that fallsback to the default openremote theme rather than just breaking.
# See this issue for aarch64 support:
# 
#    https://github.com/keycloak/keycloak-containers/issues/341
# ------------------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi8/openjdk-11-runtime
MAINTAINER support@openremote.io

# Add git commit label must be specified at build time using --build-arg GIT_COMMIT=dadadadadad
ARG GIT_COMMIT=unknown
LABEL git-commit=$GIT_COMMIT

ENV KEYCLOAK_VERSION 16.0.0
ENV JDBC_POSTGRES_VERSION 42.2.5
ENV JDBC_MYSQL_VERSION 8.0.22
ENV JDBC_MARIADB_VERSION 2.5.4
ENV JDBC_MSSQL_VERSION 8.2.2.jre11

ENV LAUNCH_JBOSS_IN_BACKGROUND 1
ENV JBOSS_HOME /opt/jboss/keycloak
ENV LANG en_US.UTF-8

ENV DB_VENDOR ${DB_VENDOR:-postgres}
ENV DB_ADDR ${DB_ADDR:-postgresql}
ENV DB_PORT ${DB_PORT:-5432}
ENV DB_DATABASE ${DB_DATABASE:-openremote}
ENV DB_USER ${DB_USER:-postgres}
ENV DB_PASSWORD ${DB_PASSWORD:-postgres}
ENV DB_SCHEMA ${DB_SCHEMA:-public}
ENV KEYCLOAK_USER ${KEYCLOAK_USER:-admin}
ENV KEYCLOAK_PASSWORD ${SETUP_ADMIN_PASSWORD:-secret}
ENV PROXY_ADDRESS_FORWARDING ${PROXY_ADDRESS_FORWARDING:-true}
ENV KEYCLOAK_FRONTEND_URL ${KEYCLOAK_FRONTEND_URL:-}
ENV TZ ${TZ:-Europe/Amsterdam}

ARG GIT_REPO
ARG GIT_BRANCH
ARG KEYCLOAK_DIST=https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz

USER root

RUN microdnf update -y && microdnf install -y glibc-langpack-en gzip hostname openssl tar which && microdnf clean all

ADD tools /opt/jboss/tools
RUN chmod -R +x /opt/jboss/tools
RUN /opt/jboss/tools/build-keycloak.sh

RUN mkdir -p /opt/jboss/keycloak/providers
RUN mkdir -p /deployment/keycloak/themes
ADD themes /opt/jboss/keycloak/themes
ADD module.xml /opt/jboss/keycloak/providers
ADD build/image/openremote-keycloak.jar /opt/jboss/keycloak/providers

HEALTHCHECK --interval=3s --timeout=3s --start-period=30s --retries=30 CMD curl --fail --silent http://localhost:8080/auth || exit 1

USER 1000

EXPOSE 8080
EXPOSE 8443

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]

CMD ["-b", "0.0.0.0"]
