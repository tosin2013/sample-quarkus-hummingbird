ARG BUILDER_IMAGE=quay.io/hummingbird-hatchling/openjdk:21-builder
ARG RUNTIME_IMAGE=quay.io/hummingbird-hatchling/openjdk:21-runtime

# Stage 1: Build the Quarkus application
FROM ${BUILDER_IMAGE} AS builder

WORKDIR /build
COPY . .
RUN ./mvnw package -DskipTests -Dmaven.repo.local=/build/.m2

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
