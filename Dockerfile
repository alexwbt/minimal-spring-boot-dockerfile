
#
# Builder image
#
FROM amazoncorretto:21-alpine3.16 as builder
WORKDIR /app

# build runtime jre
RUN apk add --no-cache binutils

RUN $JAVA_HOME/bin/jlink \
    --verbose \
    --add-modules ALL-MODULE-PATH \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=zip-9 \
    --output /runtime-jre

RUN rm -rf /runtime-jre/legal &&\
    find /runtime-jre/bin -type f \
         ! -name java \
         ! -name jcmd \
         -delete

# build application with maven wrapper
COPY .mvn .mvn
COPY mvnw .
COPY pom.xml .
RUN ./mvnw dependency:resolve

COPY src ./src
RUN ./mvnw -Dmaven.test.skip=true package


#
# Runtime image
#
FROM alpine:3.19.0
WORKDIR /app

# copy jre
ENV JAVA_HOME=/jre
ENV PATH="${JAVA_HOME}/bin:${PATH}"
COPY --from=builder /runtime-jre $JAVA_HOME

# copy jar
COPY --from=builder /app/target/runtime.jar runtime.jar

ENTRYPOINT ["java", "-jar", "runtime.jar"]
EXPOSE 8080
