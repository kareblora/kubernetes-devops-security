@Library('slack') _

pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "kareblora/numeric-app:${GIT_COMMIT}"
    applicationURL = "http://devsecops-demo-kar.eastus.cloudapp.azure.com"
    applicationURI = "/increment/99"
  }

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
            post { 
                  always { 
                    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'  
                  }    
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
              parallel(
                "Dependency Scan": {
                  sh "mvn dependency-check:check"
                },
                "Trivy Scan": {
                  sh "bash trivy-docker-image-scan.sh"
                },
                "OPA Conftest": {
                  sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
                },                
              )
            }
      }
      stage('Docker build and push') {
            steps {
              withDockerRegistry(credentialsId: 'docker-hub', url: '') {
                sh 'printenv'
                sh 'sudo docker build -t kareblora/numeric-app:""$GIT_COMMIT"" .'
                sh 'docker push kareblora/numeric-app:""$GIT_COMMIT""'
              }
            }
      }  
     
      stage('Vulnerability Scan - Kubernetes') {
            steps {
              parallel(
                "OPA Scan": {
                  sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
                },
                "Kubesec Scan": {
                  sh "bash kubesec-scan.sh"
                },  
                "Trivy Scan": {
                  sh "bash trivy-k8s-scan.sh"
                },                            
              )
            }
      }      

      stage('Kubernetes deployment - DEV') {
            steps {
              parallel(
                "Deployment": {
                  withKubeConfig(credentialsId: 'kubeconfig') {
                    sh 'bash k8s-deployment.sh'
                  }
                },
                "Rollout Status": {
                  withKubeConfig(credentialsId: 'kubeconfig') {
                    sh 'bash k8s-deployment-rollout-status.sh'
                  }
                },             
              )
            }
      }
      stage('Integration Test - DEV') {
            steps {
              script {
                try {
                  withKubeConfig(credentialsId: 'kubeconfig') {
                    sh 'bash integration-test.sh'
                  }
                } catch (e) {
                  withKubeConfig(credentialsId: 'kubeconfig') {
                    sh "kubectl -n default rollout undo deployment ${deploymentName}"
                  }
                  throw e
                }
              }
            }
      }
      stage('OWASP ZAP - DAST') {
            steps {
              withKubeConfig(credentialsId: 'kubeconfig') {
                sh 'bash zap.sh'
              }
            }
      }     
      stage('Prompt to Prod?') {
            steps {
              timeout(time: 2, unit: 'DAYS') {
                input 'Do you want to Approve the Deployment to Production Environment/Namespace'
              } 
            }
      }   
      stage('K8s CIS benchmark') {
            steps {
              script {
                parallel(
                  "Master": {
                      sh 'bash cis-master.sh'
                  },
                  "Etcd": {
                      sh 'bash cis-etcd.sh'
                  },       
                  "Worker": {
                      sh 'bash cis-worker.sh'
                  },      
                )
              }
            }
      }
        stage('Kubernetes deployment - PROD') {
            steps {
              parallel(
                "Deployment": {
                  withKubeConfig(credentialsId: 'kubeconfig') {
                    sh 'sed -i "s#replace#${imageName}#g" k8s_PROD-deployment_service.yaml'
                    sh 'kubectl -n prod apply -f k8s_PROD-deployment_service.yaml'
                  }
                },
                "Rollout Status": {
                  withKubeConfig(credentialsId: 'kubeconfig') {
                    sh 'bash k8s-PROD-deployment-rollout-status.sh'
                  }
                },             
              )
            }
      }
  }
  post { 
      always { 
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
          sendNotification currentBuild.result
        //  pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'                    
      }
  }   
}