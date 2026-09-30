# ============================================================
# Stage 1 - Build
# ============================================================
FROM maven:3.9-eclipse-temurin-21-alpine AS build

WORKDIR /build

COPY pom.xml .

RUN mvn -B dependency:go-offline

COPY src ./src

RUN mvn -B -DskipTests package


# ============================================================
# Stage 2 - Runtime
# ============================================================
FROM amazoncorretto:21-alpine

RUN addgroup -S appgroup \
    && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=build /build/target/habit-tracker.jar /app/app.jar

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
