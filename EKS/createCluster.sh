#!/bin/bash

source getClusterInfo.sh #파일로부터 명령을 읽음 source

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#(1) EKS 클러스터 Role 생성
echo '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"eks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' > eks-role-${EKS_NAME}-trust-policy.json
aws iam create-role --role-name awscli-${EKS_NAME}-cluster-role --assume-role-policy-document file://eks-role-${EKS_NAME}-trust-policy.json

#policy 생성
echo '{"Version": "2012-10-17","Statement": [{"Action":"cloudwatch:PutMetricData","Resource": "*","Effect": "Allow"}]}' > awscli-${EKS_NAME}-cluster-PolicyCloudWatchMetrics.json
aws iam create-policy --policy-name awscli-${EKS_NAME}-cluster-PolicyCloudWatchMetrics --policy-document file://awscli-${EKS_NAME}-cluster-PolicyCloudWatchMetrics.json

echo '{"Version": "2012-10-17","Statement": [{"Action":"cloudwatch:PutMetricData","Resource": "*","Effect": "Allow"}]}' > awscli-${EKS_NAME}-cluster-PolicyNLB.json
aws iam create-policy --policy-name awscli-${EKS_NAME}-cluster-PolicyNLB --policy-document file://awscli-${EKS_NAME}-cluster-PolicyNLB.json

#policy attach
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-cluster-role --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/awscli-${EKS_NAME}-cluster-PolicyCloudWatchMetrics" 
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-cluster-role --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/awscli-${EKS_NAME}-cluster-PolicyNLB" 
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-cluster-role --policy-arn "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" 
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-cluster-role --policy-arn "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"



#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#(2) EKS Cluster Subnet 설정
TOTAL_SUBNETS=(${PUBLIC_SUBNET[@]} ${FRONTEND_PRIVATE_SUBNETS[@]} ${BACKEND_PRIVATE_SUBNETS[@]} ${MANAGE_PRIVATE_SUBNETS[@]} ${INTELLISYS_PRIVATE_SUBNETS[@]})

string_total_subnet=""
for i in ${TOTAL_SUBNETS[@]}; do
    string_total_subnet+="$i,"
 done

 echo "[Total Subnet Array -> String 변경] : " ${string_total_subnet}


#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#(3) CLUSTER 생성
#securityGroupId => 추가 보안그룹으로 들어가짐
aws eks create-cluster --name ${EKS_NAME} --kubernetes-version 1.16 --role-arn arn:aws:iam::${ACCOUNT_ID}:role/awscli-${EKS_NAME}-cluster-role --resources-vpc-config subnetIds=${string_total_subnet},endpointPublicAccess=true,endpointPrivateAccess=false --tags BillingTags="Service",Name="${EKS_NAME}" 


#echo '현재 클러스터 상태 ' ${cluster_status}
while [ $(aws eks describe-cluster --name ${EKS_NAME} --query cluster.status) != "\"ACTIVE\"" ] #CREATING인 동안 루프돌아.
do
        cluster_status=$(aws eks describe-cluster --name ${EKS_NAME} --query cluster.status)
        echo -en '['$(date)'] 클러스터 생성중'${cluster_status}'\r' 
        sleep 10
        #if active
        #    break
done

echo '클러스터 생성완료!'

EKS_CLUSTER_SG_id=$(aws eks describe-cluster --name ${EKS_NAME} --query cluster.resourcesVpcConfig.clusterSecurityGroupId | tr -d '"')
echo '생성된 클러스터의 Security Group ID ' ${EKS_CLUSTER_SG_id}

## cluster-sg-id 파일로 생성
echo 'CLUSTER_SG_ID='${EKS_CLUSTER_SG_id} >> getClusterInfo.sh