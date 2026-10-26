
FROM eclipse-temurin:17-jre-alpine
LABEL maintainer="equipe-devops@esprit.tn"
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8089
ENTRYPOINT ["java", "-jar", "app.jar"]
