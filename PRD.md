# PRD: Sample Quarkus Application Repository for Hummingbird Workshop

## Purpose

A public Git repository containing a minimal Quarkus REST application with a multi-stage Containerfile that uses Project Hummingbird images. This repo is referenced by the Zero CVE Hummingbird Workshop (Module 2) as the source for Shipwright builds on OpenShift.

This continues the Quarkus theme from Module 1.1 where students built a Quarkus app locally with Podman. In Module 2.1, they bring the same pattern to OpenShift with Shipwright.

## Which Workshop Modules Use This Repo

- **Module 2.1** (Building with Hummingbird on OpenShift) -- primary consumer, builds with `buildah` ClusterBuildStrategy
- **Module 2.3** (Security Pipeline & Production) -- builds with `hummingbird-secure-build` ClusterBuildStrategy

Module 2.2 tests multi-language auto-detection using `shipwright-io/sample-nodejs` (Node.js) to demonstrate the strategy can handle a different language than 2.1's Java.

## Requirements

1. Must be a **public** Git repository (Shipwright clones without auth)
2. Must contain a `Containerfile` at the repo root
3. The application must listen on **port 8080** (OpenShift / Quarkus default)
4. The application must respond to `GET /hello` and `GET /q/health` endpoints
5. The Containerfile must use **Hummingbird builder and runtime images** from `quay.io/hummingbird-hatchling`
6. The final image must run as **non-root** (UID 65532, Hummingbird default)
7. Must include the Maven wrapper (`mvnw`) so builds work without pre-installed Maven

## How to Create This Repo

### Option A: Generate with Quarkus CLI (recommended)

```bash
# 1. Scaffold the project
quarkus create app com.example:sample-quarkus-hummingbird \
    --extension='rest,rest-jackson,smallrye-health' \
    --no-code
cd sample-quarkus-hummingbird

# 2. Replace the .dockerignore (Quarkus default excludes source files)
cat > .dockerignore << 'EOF'
target/
.git/
.gitignore
*.md
!README.md
EOF

# 3. Create the REST endpoint
mkdir -p src/main/java/com/example
# Copy GreetingResource.java from this PRD (see below)

# 4. Copy the Containerfile from this PRD (see below)

# 5. Test locally
./mvnw package -DskipTests
java -jar target/quarkus-app/quarkus-run.jar
curl http://localhost:8080/hello

# 6. Push
git init && git add . && git commit -m "Initial Quarkus app with Hummingbird Containerfile"
git branch -M main
git remote add origin https://github.com/tosin2013/sample-quarkus-hummingbird.git
git push -u origin main
```

### Option B: Use the provided files directly

All source files are included alongside this PRD. Copy them into a fresh Git repo.
Note: You still need the Maven wrapper. Either generate with `quarkus create app` (above)
or run `mvn wrapper:wrapper` in the project directory.

## File: `Containerfile`

```dockerfile
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
```

## File: `src/main/java/com/example/GreetingResource.java`

```java
package com.example;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/hello")
public class GreetingResource {

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public String hello() {
        return "{\"message\":\"Hello from Hummingbird!\",\"runtime\":\"Quarkus + JDK " +
               System.getProperty("java.version") + "\"}";
    }
}
```

## File: `src/main/resources/application.properties`

```properties
quarkus.http.port=8080
```

## File: `.dockerignore`

```
target/
.git/
.gitignore
*.md
!README.md
```

## Image Details

### Builder: `quay.io/hummingbird-hatchling/openjdk:21-builder`

- JDK 21.0.10, JAVA_HOME=/usr/lib/jvm/default-jvm
- Includes bash and dnf (builder variant)
- Maven wrapper (`./mvnw`) downloads Maven at build time
- Verified available: tags `21-builder`, `25-builder`, `latest-builder`

### Runtime: `quay.io/hummingbird-hatchling/openjdk:21-runtime`

- JRE only, distroless -- no shell, no package manager
- Non-root UID 65532 by default
- 33 content-based layers (chunkah)
- Near-zero CVEs
- Verified available: tags `21-runtime`, `25-runtime`, `latest-runtime`

## Endpoints

- `GET /hello` -- returns JSON `{"message":"Hello from Hummingbird!","runtime":"Quarkus + JDK 21.0.10"}`
- `GET /q/health` -- Quarkus SmallRye Health check (auto-provided by `smallrye-health` extension)
- `GET /q/health/live` -- Liveness probe
- `GET /q/health/ready` -- Readiness probe

## Verification (March 15, 2026)

Both images confirmed public and pullable:

```
skopeo inspect docker://quay.io/hummingbird-hatchling/openjdk:21-builder
skopeo inspect docker://quay.io/hummingbird-hatchling/openjdk:21-runtime
```

## Repository Owner

- **GitHub**: tosin2013
- **Name**: Tosin Akinosho
- **Email**: takinosh@redhat.com
- **Repo URL**: https://github.com/tosin2013/sample-quarkus-hummingbird
