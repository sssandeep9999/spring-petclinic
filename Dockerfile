# Stage 1: Build
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests -Dcheckstyle.skip=true

# Stage 2: Runtime (FIXED)
FROM eclipse-temurin:17-jre

WORKDIR /app

# ✅ correct package manager (Debian-based)
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Copy jar from stage-1 (build)
COPY --from=build /app/target/spring-petclinic-4.0.0-SNAPSHOT.jar app.jar

EXPOSE 8080

# ✅ Correct ENTRYPOINT format
ENTRYPOINT ["java", "-jar", "app.jar"]

