ARG BUILDER_IMAGE=quay.io/hummingbird-hatchling/openjdk:21-builder
ARG RUNTIME_IMAGE=quay.io/hummingbird-hatchling/openjdk:21-runtime

# Stage 1: Build the Quarkus application
FROM ${BUILDER_IMAGE} AS builder

USER root
RUN microdnf install -y tar gzip && \
    curl -L https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | tar -xz -C /opt && \
    ln -s /opt/apache-maven-3.9.9/bin/mvn /usr/local/bin/mvn && \
    mkdir -p /build/.m2 && chown -R 1001:1001 /build && \
    microdnf clean all

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk

WORKDIR /build
COPY --chown=1001:1001 . .
USER 1001

RUN mvn package -DskipTests -Dmaven.repo.local=/build/.m2

# Stage 2: Copy only the runtime artifacts into the distroless runtime
FROM ${RUNTIME_IMAGE}

WORKDIR /app
COPY --from=builder /build/target/quarkus-app/lib/ ./lib/
COPY --from=builder /build/target/quarkus-app/*.jar ./
COPY --from=builder /build/target/quarkus-app/app/ ./app/
COPY --from=builder /build/target/quarkus-app/quarkus/ ./quarkus/

USER 65532
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "quarkus-run.jar"]
