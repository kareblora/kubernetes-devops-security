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
      stage('Mutation Tests - PIT') {
            steps {
              sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
            post {
              always {
                pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
              }
            }
        } 
      stage('Sonarqube - SAST') {
            steps {
              sh "mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://devsecops-demo-kar.eastus.cloudapp.azure.com:9000 -Dsonar.login=sqp_1e099b6890364dfeb54fe1c45e5ad6a9b1ad556e"
            }
        } 

      stage('Docker build and push') {
            steps {
              withDockerRegistry(credentialsId: 'docker-hub', url: '') {
                sh 'printenv'
                sh 'docker build -t kareblora/numeric-app:""$GIT_COMMIT"" .'
                sh 'docker push kareblora/numeric-app:""$GIT_COMMIT""'
              }
            }
      }  
      stage('Kubernetes deployment - DEV') {
            steps {
              withKubeConfig(credentialsId: 'kubeconfig') {
                sh "sed -i 's#replace#kareblora/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                sh 'kubectl apply -f k8s_deployment_service.yaml'
              }
            }
      }
    
    }
}
