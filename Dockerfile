# Build stage
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Copy Gradle wrapper and build files
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# Grant execute permission to gradlew
RUN chmod +x gradlew

# Download dependencies (cache layer)
RUN ./gradlew dependencies --no-daemon || true

# Copy source code
COPY src src

# Build application
RUN ./gradlew clean bootJar --no-daemon

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring

# Copy JAR from build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Change ownership to non-root user
RUN chown spring:spring app.jar

# Switch to non-root user
USER spring:spring

# Expose port
EXPOSE 8080

# Health check (simple port check - customize if you add Spring Boot Actuator)
# HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
#   CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
