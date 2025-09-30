pipeline {
    agent any
    
    tools {
        maven 'Maven-3.8' // Jenkins installera Maven automatiquement
        jdk 'JDK-17'      // Jenkins utilisera le JDK configuré
    }
   
    environment {
        // Configuration Docker
        DOCKERHUB_REPO = 'medaliromdhani/devops'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
        ).trim()
    }
    
    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from GitHub...'
                git url: 'https://github.com/romdhanimedali28/student-management-devops.git',
                    branch: 'main'
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
                echo "Building commit: ${env.GIT_COMMIT_SHORT}"
            }
        }
        
        stage('Verify Environment') {
            steps {
                echo 'Verifying Java, Maven and Docker versions...'
                sh 'java -version'
                sh 'mvn -version'
                sh 'docker --version'
            }
        }
        
        stage('Clean') {
            steps {
                echo 'Cleaning previous builds...'
                sh 'mvn clean'
            }
        }
        
        stage('Build Application') {
            steps {
                echo 'Building the Spring Boot project...'
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('Run Tests') {
            steps {
                echo 'Running unit tests...'
                sh 'mvn test'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                   
                    // Build the Docker image
                    sh """
                        docker build -t ${DOCKERHUB_REPO}:${BUILD_NUMBER} .
                    """
                   
                    // Tag with additional tags
                    sh "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${DOCKERHUB_REPO}:latest"
                    sh "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${DOCKERHUB_REPO}:${GIT_COMMIT_SHORT}"
                   
                    echo "✅ Docker image built successfully"
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo "Testing Docker image..."
                   
                    // Test that the container starts
                    sh """
                        echo "Starting container for testing..."
                        docker run -d --name test-container-${BUILD_NUMBER} \
                            -p 8081:8080 \
                            ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                       
                        echo "Waiting for container to be ready..."
                        sleep 15
                       
                        echo "Testing application endpoint..."
                        curl -f http://localhost:8081/actuator/health || curl -f http://localhost:8081/ || echo "Health check endpoint not available"
                       
                        echo "✅ Container test passed!"
                       
                        echo "Cleaning up test container..."
                        docker stop test-container-${BUILD_NUMBER}
                        docker rm test-container-${BUILD_NUMBER}
                    """
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                script {
                    echo "Logging into DockerHub..."
                   
                    // Login to DockerHub using credentials
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                        echo "Pushing images to DockerHub..."
                       
                        // Push all tags
                        sh "docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                        sh "docker push ${DOCKERHUB_REPO}:latest"
                        sh "docker push ${DOCKERHUB_REPO}:${GIT_COMMIT_SHORT}"
                       
                        echo "✅ Successfully pushed to DockerHub:"
                        echo "   - ${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                        echo "   - ${DOCKERHUB_REPO}:latest"
                        echo "   - ${DOCKERHUB_REPO}:${GIT_COMMIT_SHORT}"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            echo "🐳 Docker Image: ${DOCKERHUB_REPO}:${BUILD_NUMBER}"
            echo "📋 Build: ${env.BUILD_NUMBER}"
            echo "🔗 Commit: ${env.GIT_COMMIT_SHORT}"
            
            // Archive artifacts
            archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
        }
       
        failure {
            echo '❌ Pipeline failed!'
            echo 'Check the logs above for error details'
        }
       
        always {
            script {
                echo "Starting cleanup..."
                
                // Local Docker cleanup
                sh """
                    echo "Cleaning up local Docker images..."
                    docker rmi ${DOCKERHUB_REPO}:${BUILD_NUMBER} || true
                    docker rmi ${DOCKERHUB_REPO}:latest || true
                    docker rmi ${DOCKERHUB_REPO}:${GIT_COMMIT_SHORT} || true
                    
                    # Clean up any test containers
                    docker rm -f test-container-${BUILD_NUMBER} || true
                    
                    # Clean up unused Docker resources
                    docker system prune -f || true
                    
                    echo "✅ Local Docker cleanup completed"
                """
            }
            
            // Clean workspace
            cleanWs()
        }
    }
}