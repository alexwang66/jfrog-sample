FROM eclipse-temurin:17-jre-alpine

WORKDIR /app
COPY maven-sample/target/app-boot-1.0.3.war app.war

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.war"]
