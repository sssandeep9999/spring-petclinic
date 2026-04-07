# Stage 1: Build
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime (FIXED)
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# 🔥 Update OS packages (Fix Trivy HIGH issues)
RUN apk update && apk upgrade

# Copy jar
COPY --from=build /app/target/spring-petclinic-4.0.0-SNAPSHOT.jar app.jar

EXPOSE 8080

# ✅ Correct ENTRYPOINT format
ENTRYPOINT ["java", "-jar", "app.jar"]

