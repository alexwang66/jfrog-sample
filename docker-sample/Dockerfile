FROM eclipse-temurin:17-jre

WORKDIR /app
COPY target/app-boot-1.0.3.war app.war

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.war"]
