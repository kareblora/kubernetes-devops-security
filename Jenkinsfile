pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar'  
            }
        }   
      stage('Unit test - JUnit and Jacoco') {
            steps {
              sh "mvn test"
            }
            post {
              always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
              }
            }
        }  
      stage('Docker build and push') {
            steps {
              withDockerRegistry([credentialsID: "docker-hub", url: ""]) {
                sh 'printenv'
                sh 'docker build -t kareblora/numeric-app:""$GIT_COMMIT""'
                sh 'docker push kareblora/numeric-app:""$GIT_COMMIT""'
              }
            }
        }       
    }
}
