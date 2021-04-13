/*
ENV :  PROD
PROJECT : ifmng
CD_TYPE :  blue-green
*/

import groovy.transform.Field
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@Field def CONFIG_ENV ="prod"
@Field def CLUSTER_ENV ="gsn-kym-eks"
@Field def PROJECT_NAME = "backend-emp"
@Field def ECR_CREDENTIAL = "aws-ecr"
@Field def GIT_OPS_NAME = "gitops"
@Field def BASE_ECR = "backend-base"

def gitUrl = "https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/${PROJECT_NAME}"
def envBranch = "master"

def gitOpsUrl = "https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/${GIT_OPS_NAME}"
def opsBranch = "backend-emp"

def ecrRepository = "058475846659.dkr.ecr.ap-northeast-2.amazonaws.com"

def dockerScanningUrl = "https://ap-northeast-2.console.aws.amazon.com/ecr/repositories/${PROJECT_NAME}/?region=ap-northeast-2"

@Field def argocdContext = "${CONFIG_ENV}-${CLUSTER_ENV}-context"

@Field def TAG

pipeline {
    environment {        
        PATH = "$PATH:/usr/local/bin/"  //skaffold, argocd, jq
      }
    agent any   
    
    stages {   
        stage('Git Clone') {           
            steps {            
                script {
                    try {
                        print("=================Git clone start=================")
                        git branch: "${envBranch}", url: "${gitUrl}", credentialsId: "jenkins_code_commit" 
                        def cmd = "aws ecr list-images --repository-name ${BASE_ECR} --output text --query \"imageIds[?imageTag=='latest'].imageDigest\" --region ap-northeast-2"
                        def digest =  executeCmdReturn(cmd)
                        
                        // digest 
                        sh("sed -i 's!<digest>.*!<digest>${digest}</digest>!g' /var/lib/jenkins/workspace/${JOB_NAME}/pom.xml")
                        
                        
                        env.gitcloneResult = true  
                    }
                    catch(Exception e) {
                        print(e)
                        cleanWs()
                        // update_issue(41)
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }

        stage('Build') {
            when {
                expression {
                    return env.gitcloneResult ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/
                }
            }              
            steps {            
                script {
                    try {
                        print("=================Build start=================")
                        sh "aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${ecrRepository}"
                        TAG = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss.SSS"));
                        
                        print("TAG:"+ TAG)
                        docker.withRegistry("https://${ecrRepository}","ecr:ap-northeast-2:aws-ecr"){
                            sh "VER=${TAG} skaffold build -p ${CONFIG_ENV} --cache-artifacts=false"
                        }
                        env.buildResult = true  
                    }
                    catch(Exception e) {
                        print(e)
                        // update_issue(41)
                        currentBuild.result = 'FAILURE'
                    }
                    finally {
                        cleanWs()   
                    }
                }
            }
        }
        stage('Docker Scanning') {
            when {
                expression {
                    return env.buildResult ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/
                }
            }
            steps {
                script {
                    try {        
                        print("=================Docker Scanning start=================")                
                        def cmd = "aws ecr describe-image-scan-findings --repository-name ${PROJECT_NAME} --image-id imageTag=${TAG} --region ap-northeast-2 --query \"imageScanStatus.status\" --region ap-northeast-2"
                        def result = ""
                        while(true) {
                            try {
                                result = executeCmdReturn(cmd)
                            }
                            catch(Exception e) {
                                print("--- Start Scan ---")
                                sh "aws ecr start-image-scan --repository-name ${PROJECT_NAME} --image-id imageTag=${TAG} --region ap-northeast-2"       
                                sleep 3
                            }                           
                            print(result)
                            if(result == "\"COMPLETE\"")
                                break
                            sleep 1
                        }

                        cmd = "aws ecr describe-image-scan-findings --repository-name ${PROJECT_NAME} --image-id imageTag=${TAG} --region ap-northeast-2 --query \"imageScanFindings.findingSeverityCounts\""
                        print("--- Scanning Result ---") 
                        print(executeCmdReturn(cmd))

                        env.scanningResult = true
                    }
                    catch(Exception e) {
                        print(e)
                        // update_issue(41)
                        currentBuild.result = 'FAILURE'
                    }
                    finally {
                        cleanWs()
                    }
                }
            }
        }
        
        stage('GitOps') {
            when {
                expression {
                    return env.scanningResult ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/
                }
            }
            steps {
                script{
                    try {
                        print("=================GitOps start=================")   

                        git branch: "${opsBranch}", url: "${gitOpsUrl}", credentialsId: "jenkins_code_commit"

                        sh "cat ./deployment/deployment.yaml"

                        sh("sed -i \"s/${PROJECT_NAME}:.*/${PROJECT_NAME}:${TAG}/g\" ./deployment/deployment.yaml")
                        
                        sh "cat ./deployment/deployment.yaml"

                        sh("git add .; git commit -m 'trigger generated tag : ${TAG}'")
                        sh("git push origin ${opsBranch} ") 
                        print "git push finished !!!"
                        env.gitOpsReulst = true
                    }
                    catch(Exception e) {
                        print(e)
                        // update_issue(41)
                        currentBuild.result = 'FAILURE'
                    }
                    finally {
                        cleanWs()   
                    }
                }
            }
        }
        stage('argocd sync') {
            when {
                expression {
                    return env.gitOpsReulst ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/
                }
            } 
            steps {
                script {
                    try {
                        sh("argocd context ${argocdContext} ")

                        print "======project: ${PROJECT_NAME} sync"

                        def cmd = " argocd app get ${PROJECT_NAME} --show-operation -o json | jq '.status.sync.revision' "
                        def originSyncRevision =  executeCmdReturn(cmd)

                        print "originSyncRevision: ${originSyncRevision}"

                        sh("argocd app sync ${PROJECT_NAME}")

                        def sleepTime = 5
                        def maxTime = 600
                        print "maxTime: ${maxTime}"

                        sleep sleepTime

                        def x = loopHealthCheck(maxTime, sleepTime , originSyncRevision) 

                        if(x >= maxTime){
                            print "-----error sync timeout !!!------------"
                            error " Failure Reason:  Health Checking  Max Time Out"
                        }
                        // update_issue(31)
                    }
                    catch(Exception e) {
                        print(e)
                        // update_issue(41)
                        currentBuild.result = 'FAILURE'
                    }
                    finally {
                        cleanWs()
                    }
                    
                }
            }
        } 
    }
}

def update_issue(transition_id) {
    sh "curl -X POST -H \"X-API-KEY: ${API_KEY}\" -H \"x-issue-id: ${issue_id}\" -H \"x-transition-id: ${transition_id}\" -H \"BuildInfo: ${env.JOB_NAME}/${env.BUILD_NUMBER}\" -H \"Content-type: application/json\" ${AGW_URL}/done-issue"
}

def check_context() {
  def cmd = "argocd context | awk '\$1==\"*\" {print \$2}'"
  return executeCmdReturn(cmd)
}

def loopHealthCheck(maxTime, sleepTime, originSyncRevision){
    def argocdContext = "${argocdContext}"
    print "loopHealthCheck......"
    for (x = 0; x <= maxTime ; (x += sleepTime) ) { 
        def cmd = " argocd app get ${PROJECT_NAME} --show-operation -o json | jq '.status.sync.revision' "
        def newSyncRevision = ""
        
        if(check_context() == argocdContext) {
            newSyncRevision = executeCmdReturn(cmd)
        } else {
            sh("argocd context ${argocdContext} ")
            newSyncRevision = executeCmdReturn(cmd)
        }
        
        print "originSyncRevision: ${originSyncRevision} <-> newSyncRevision: ${newSyncRevision}"
        
        if(originSyncRevision != newSyncRevision){    
            cmd = " argocd app get ${PROJECT_NAME} --show-operation -o json | jq '.status.sync.status' "
            def syncStatus = ""
            if(check_context() == argocdContext) {
                syncStatus = executeCmdReturn(cmd)
            } else {
                sh("argocd context ${argocdContext} ")
                syncStatus = executeCmdReturn(cmd)
            }

            cmd = " argocd app get ${PROJECT_NAME} --show-operation -o json | jq '.status.health.status' "
            def healthStatus = ""
            if(check_context() == argocdContext) {
                healthStatus = executeCmdReturn(cmd)
            } else {
                sh("argocd context ${argocdContext} ")
                healthStatus = executeCmdReturn(cmd)
            }
            print "syncStatus : ${syncStatus} --- healthStatus:${healthStatus}"

            if((replaceText(syncStatus) == "Synced" ) && (replaceText(healthStatus) == "Healthy")){
                print "HealthStatus Healthy  Sync Completed !!!!!"
                break;
            }
        }else{
            print "Argo Sync Continuing......."
            print "Waiting.........."        
            print ""        
        }
        print "x:"+x
        sleep sleepTime
    }
    return x
}

def executeCmdReturn(cmd){
  return sh(returnStdout: true, script: cmd).trim()
}

def replaceText(str){
    return str.replaceAll('"','')
}