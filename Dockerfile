ARG BASE_IMAGE=eclipse-temurin:25-jre
FROM ${BASE_IMAGE}

ENV HYTALE_HOME="/opt/hytale"
ENV DATA_DIR="/data"

ENV UID=1000
ENV GID=1000

# Setup users and dependencies
RUN --mount=target=/build,source=build \
    /build/setup.sh

# Create directories
RUN mkdir -p $HYTALE_HOME $DATA_DIR

WORKDIR $HYTALE_HOME

# Copy scripts
COPY scripts/ /scripts/
COPY entrypoint.sh .
RUN chmod +x /scripts/*.sh entrypoint.sh

VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/tini", "--", "./entrypoint.sh"]
