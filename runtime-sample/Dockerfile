FROM demo.jfrogchina.com/j-docker-local/yunxiao:openjdk_11-alpine3.20-latest

WORKDIR /app
COPY maven-sample/target/app-boot-1.0.3.war app.war

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.war"]
