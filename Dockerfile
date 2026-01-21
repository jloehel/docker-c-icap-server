ARG OS_FLAVOR=fedora
ARG OS_VERSION=43

FROM ${OS_FLAVOR}:${OS_VERSION}

ARG ARCH
ARG OS_FLAVOR=fedora
ARG OS_VERSION=43
ARG IMAGE_VERSION=43-0.6.3-1
ARG IMAGE_DESCRIPTION="c-icap server for content adaptation"
ARG APP_NAME=c-icap-server
ARG APP_VERSION=0.6.3
ARG APP_USERNAME=c-icap
ARG APP_UID=1001
ARG APP_GID=0

LABEL maintainer="Jürgen Löhel <juergen@loehel.de>"
LABEL org.opencontainers.image.title="c-icap-server Docker image by jloehel"
LABEL org.opencontainers.image.authors="Jürgen Löhel"
LABEL org.opencontainers.image.source="https://github.com/jloehel/docker-${APP_NAME}"
LABEL org.opencontainers.image.url="https://github.com/jloehel/docker-${APP_NAME}"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.description="${IMAGE_DESCRIPTION}"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.${OS_FLAVOR}.version="${OS_VERSION}"
LABEL org.${APP_NAME}.version="${APP_VERSION}"

ENV ARCH="${ARCH}" \
    OS_FLAVOR="${OS_FLAVOR}" \
    OS_VERSION="${OS_VERSION}" \
    APP_NAME="${APP_NAME}" \
    APP_VERSION="${APP_VERSION}" \
    APP_USERNAME="${APP_USERNAME}" \
    CICAP_HOME="/opt/c-icap" \
    CICAP_RUN="/run/c-icap" \
    NSS_WRAPPER_GROUP="/opt/c-icap/nss_group" \
    NSS_WRAPPER_PWD="/opt/c-icap/nss_passwd"

COPY ./overlay /

RUN set -eux; \
    . /build/install-dependencies.sh && \
    . /build/install-app.sh && \
    . /build/setup-permissions.sh && \
    . /build/clean.sh

EXPOSE 1344

WORKDIR /opt/c-icap
USER ${APP_UID}
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ["/healthcheck.sh"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/run.sh"]
