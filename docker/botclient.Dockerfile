FROM eclipse-temurin:17-jre

WORKDIR /opt/client
COPY java_dist/BotClient-1.1.9-SNAPSHOT/ ./

RUN mkdir -p /usr/local/bin && \
    ln -s /opt/client/bin/BotClient /usr/local/bin/client

WORKDIR /app

ENTRYPOINT ["client"]
