FROM eclipse-temurin:25-jre

ENV HYTALE_HOME="/opt/hytale"
ENV DATA_DIR="/data"

ENV UID=1000
ENV GID=1000

# Setup user
COPY build/setup_user.sh /tmp/
RUN chmod +x /tmp/setup_user.sh && /tmp/setup_user.sh

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl unzip gosu tini  && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p $HYTALE_HOME $DATA_DIR

WORKDIR $HYTALE_HOME

# Copy scripts
COPY scripts/ /scripts/
COPY entrypoint.sh .
RUN chmod +x /scripts/*.sh entrypoint.sh

VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/tini", "--", "./entrypoint.sh"]
