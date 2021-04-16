/*
ENV :  DEV
PROJECT : adminweb
CD_TYPE :  rolling-update 
*/

import groovy.transform.Field
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@Field def CONFIG_ENV ="prod"
@Field def CLUSTER_ENV ="gsn-kym-eks"
@Field def PROJECT_NAME = "frontend-web"
@Field def ECR_CREDENTIAL = "aws-ecr"

@Field def GIT_OPS_NAME = "gitops"

@Field def NPM_PATH = "/home/jenkins/.nvm/versions/node/v14.16.1/lib/node_modules/npm"

def gitUrl = "https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/${PROJECT_NAME}"
def envBranch = "master"

def gitOpsUrl = "https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/${GIT_OPS_NAME}"
def opsBranch = "frontend-web"

def ecrRepository = "058475846659.dkr.ecr.ap-northeast-2.amazonaws.com"


@Field def argocdContext = "${CONFIG_ENV}-${CLUSTER_ENV}-context"

@Field def TAG

pipeline {
    environment {        
        PATH = "$PATH:/usr/local/bin/:${NPM_PATH}" 
      }
    agent any   
    
    stages {   
        stage('Git Clone') {           
            steps {            
                script {
                    try {
                        git branch: "${envBranch}", url: "${gitUrl}", credentialsId: "jenkins_code_commit" 
                        env.gitcloneResult = true  
                    }
                    catch(Exception e) {
                        print(e)
                        cleanWs()
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }


        stage('Build/Dockerizing') {
            when {
                expression {
                    return env.gitcloneResult ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/
                }
            }
            steps {            
                script {
                    try {

                        TAG = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss"));

                        sh """
                        aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${ecrRepository}
                        docker build -t ${PROJECT_NAME} .
                        docker tag ${PROJECT_NAME}:latest ${ecrRepository}/${PROJECT_NAME}:${TAG}
                        docker push ${ecrRepository}/${PROJECT_NAME}:${TAG}
                        """

                        env.dockerBuildResult=true
 
                    }
                    catch(Exception e) {
                        print(e)
                        env.dockerBuildResult=false
                        currentBuild.result = 'FAILURE'
                    }finally{
                        cleanWs()
                    }
                }
            }
        }
        

        stage('Docker Scanning') {
            when {
                expression {
                    return env.dockerBuildResult ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/
                }
            }
            steps {
                script {
                    try {                        
                        def cmd = "aws ecr describe-image-scan-findings --repository-name ${PROJECT_NAME} --image-id imageTag=${TAG} --region ap-northeast-2 --query \"imageScanStatus.status\""
                        def result = ""
                        while(true) {
                            try {
                                result = withAWS(credentials:"aws-ecr") {
                                    sh(returnStdout: true, script: cmd).trim()
                                }
                            }
                            catch(Exception e) {
                                print("--- Start Scan ---")
                                withAWS(credentials:"aws-ecr") {
                                    sh "aws ecr start-image-scan --repository-name ${PROJECT_NAME} --image-id imageTag=${TAG} --region ap-northeast-2"       
                                }
                                sleep 3
                            }                           
                            print(result)
                            if(result == "\"COMPLETE\"")
                                break
                            sleep 1
                        }

                        cmd = "aws ecr describe-image-scan-findings --repository-name ${PROJECT_NAME} --image-id imageTag=${TAG} --region ap-northeast-2 --query \"imageScanFindings.findingSeverityCounts\""
                        print("--- Scanning Result ---") 
                        scan_result = withAWS(credentials:"aws-ecr") {
                            sh(returnStdout: true, script: cmd).trim()
                        }
                        print(scan_result)

                        env.scanningResult = true
                    }
                    catch(Exception e) {
                        print(e)
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
                        print "======deployment.yaml tag update====="
                        git branch: "${opsBranch}", url: "${gitOpsUrl}", credentialsId: "jenkins_code_commit"
                       
                        sh("sed -i \"s/${PROJECT_NAME}:.*/${PROJECT_NAME}:${TAG}/g\" ./deployment/deployment.yaml")
                        
                        sh("git add .")
                        sh("git commit -m 'trigger generated tag : ${TAG}'")
                        sh("git push origin ${opsBranch} ") 
                        print "git push finished !!!"
                        env.gitOpsReulst = true
                    }
                    catch(Exception e) {
                        print(e)
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
                    }
                    catch(Exception e) {
                        print(e)
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