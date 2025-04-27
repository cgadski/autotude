FROM eclipse-temurin:17
# FROM amazoncorretto:17
WORKDIR /opt/client/
COPY BotClient-1.1.9-SNAPSHOT ./
RUN ln -s /opt/client/bin/BotClient /usr/local/bin/client
WORKDIR /app
ENTRYPOINT ["client"]
