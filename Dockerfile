# Stage 1: Build avec Maven
FROM maven:3.8.5-openjdk-17 AS build

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers pom.xml et télécharger les dépendances
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copier le code source
COPY src ./src

# Construire l'application (skipping tests pour accélérer)
RUN mvn clean package -DskipTests

# Stage 2: Runtime - Image légère
FROM openjdk:17-jdk-slim

# Définir le répertoire de travail
WORKDIR /app

# Copier le JAR depuis le stage de build
COPY --from=build /app/target/*.jar app.jar

# Exposer le port de l'application (généralement 8080 pour Spring Boot)
EXPOSE 8080

# Variable d'environnement optionnelle
ENV JAVA_OPTS=""

# Commande de démarrage
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]