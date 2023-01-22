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
        }  
      stage('Mutation Tests - PIT') {
            steps {
              sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
        } 
      stage('Sonarqube - SAST') {
            steps {
              withSonarQubeEnv('SonarQube') {
                sh "mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://devsecops-demo-kar.eastus.cloudapp.azure.com:9000"
            }
                timeout(time: 2, unit: 'MINUTES') {
                  script{
                    waitForQualityGate abortPipeline: true 
                  }  
            } 
        } 
      }
      stage('Vulnerability Scan - Docker') {
            steps {
              sh "mvn dependency-check:check"
            }
            post { 
                  always { 
                    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'   
                  }    
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
  post { 
      always { 
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'                
      }
    }   
}