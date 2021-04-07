#!/bin/bash

source getClusterInfo.sh #파일로부터 명령을 읽음 source

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#(6) Cluster에 nodeGroup생성 

echo '{"Version": "2012-10-17", "Statement": { "Effect": "Allow", "Principal": { "Service": "ec2.amazonaws.com"}, "Action": "sts:AssumeRole" }}' > eks-workernode-role-${EKS_NAME}-trust-policy.json
aws iam create-role --role-name awscli-${EKS_NAME}-workernode-role --assume-role-policy-document file://eks-workernode-role-${EKS_NAME}-trust-policy.json

#role policy attach
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-workernode-role --policy-arn "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" 
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-workernode-role --policy-arn "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-workernode-role --policy-arn "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-workernode-role --policy-arn "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" 
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-workernode-role --policy-arn "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

cat > EKSAutoscailerPolicy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
aws iam create-policy --policy-name EKSAutoscailerPolicy --policy-document file://EKSAutoscailerPolicy.json
aws iam attach-role-policy --role-name awscli-${EKS_NAME}-workernode-role --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/EKSAutoscailerPolicy"


cat > ALBIngressControllerPolicy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate",
                "acm:ListCertificates",
                "acm:GetCertificate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DeleteSecurityGroup",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVpcs",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DeleteRule",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:ModifyRule",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:RemoveTags",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:SetWebACL"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole",
                "iam:GetServerCertificate",
                "iam:ListServerCertificates"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "waf-regional:GetWebACLForResource",
                "waf-regional:GetWebACL",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "tag:GetResources",
                "tag:TagResources"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "waf:GetWebACL"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy --policy-name ALBIngressControllerPolicy --policy-document file://ALBIngressControllerPolicy.json
aws iam attach-role-policy --role-name eks-worker-role --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/ALBIngressControllerPolicy"



##해당 role에 policy가 잘붙어있는지 확인하기
#aws iam list-attached-role-policies --role-name awscli-${EKS_NAME}-workernode-role

##node security group 추가
#NODE_SecurityGroup=${EKS_NODEGROUP_SG_id},${EKS_CLUSTER_SHARED_NODE_SG_id}
#NODE_GROUP_NAME_LIST=("FRONTEND" "BACKEND" "MANAGE") ##**따로 변수로 빼기.

for i in ${NODE_GROUP_NAME_LIST[@]}; do
    
    NODE_GROUP_NAME=${i}
    echo "NODE_GROUP_NAME: "${i}

    nodeCapacity=${i}_NODE_COUNT
    echo "nodeCapacity: "${!nodeCapacity}

    subnetName=${i}_PRIVATE_SUBNETS[@]
    echo "subnetName: "${!subnetName}  
    ##**태그
    create_nodegroup=$(aws eks create-nodegroup --cluster-name ${EKS_NAME} --nodegroup-name ${NODE_GROUP_NAME} --scaling-config minSize=${!nodeCapacity},maxSize=${!nodeCapacity},desiredSize=${!nodeCapacity} --disk-size 20 --subnets ${!subnetName} --instance-types ${instanceType} --ami-type AL2_x86_64 --remote-access ec2SshKey=${sshKeyName} --node-role arn:aws:iam::${ACCOUNT_ID}:role/awscli-${EKS_NAME}-workernode-role --labels nodegroup-type=${NODE_GROUP_NAME} --kubernetes-version 1.16 --tag NAME=${EKS_NAME}-${NODE_GROUP_NAME}-node,ASG_STOP=true)
    

    while [ $(aws eks describe-nodegroup --cluster-name ${EKS_NAME} --nodegroup-name ${NODE_GROUP_NAME} --query nodegroup.status) != "\"ACTIVE\"" ] #CREATING인 동안 루프돌아.
    do
        nodeGroup_status=$(aws eks describe-nodegroup --cluster-name ${EKS_NAME} --nodegroup-name ${NODE_GROUP_NAME} --query nodegroup.status)
        echo -en '['$(date)'] Nodegroup Auto Scaling Group 생성중'${nodeGroup_status}'\r' 
        sleep 10
    done

    # autoscaling group 값 가져와서 네임태그 추가
    nodeGroup_status=$(aws eks describe-nodegroup --cluster-name ${EKS_NAME} --nodegroup-name ${NODE_GROUP_NAME} --query nodegroup.status) 
    if [ ${nodeGroup_status} = "\"ACTIVE\"" ];then
        #asg update
        nodegroup_asg_id=$(aws eks describe-nodegroup --cluster-name ${EKS_NAME} --nodegroup-name ${NODE_GROUP_NAME} --query nodegroup.resources.autoScalingGroups[0].name | tr -d '"')
        echo 'ASG ID - '${nodegroup_asg_id}
        
        aws autoscaling create-or-update-tags --tags ResourceId=${nodegroup_asg_id},ResourceType=auto-scaling-group,Key=Name,Value=${EKS_NAME}"-"${NODE_GROUP_NAME}"-Node",PropagateAtLaunch=true

        ##################################################
        #autoscaling group에 속한 인스턴스가져와서 강제로 네임태그 넣기! (초기에만)

        getEc2Results=$(aws autoscaling describe-auto-scaling-instances --region ap-northeast-2 --query "AutoScalingInstances[?AutoScalingGroupName=='${nodegroup_asg_id}'].InstanceId"| tr -d '"' | tr -d '[' | tr -d ']' | tr -d ',')
        echo '해당 asg에 속한 instance id list - '${getEc2Results}

        for ec2ID in ${getEc2Results[@]}; do
            echo "ec2ID -> " ${ec2ID}
            aws ec2 create-tags --resources ${ec2ID} --tags Key=Name,Value=${EKS_NAME}"-"${NODE_GROUP_NAME}"-Node"

        done
        ###################################################
        #aws autoscaling set-desired-capacity --auto-scaling-group-name ${nodegroup_asg_id} --desired-capacity 0
        #aws autoscaling set-desired-capacity --auto-scaling-group-name ${nodegroup_asg_id} --desired-capacity ${!nodeCapacity}


        # 노드그룹 inbound/outbound
        currentNodeSG=$(aws eks describe-nodegroup --cluster-name ${EKS_NAME}  --nodegroup-name ${NODE_GROUP_NAME} --query nodegroup.resources.remoteAccessSecurityGroup | tr -d '"')

        aws ec2 authorize-security-group-ingress --group-id ${currentNodeSG} --protocol tcp --port 443 --source-group ${CLUSTER_SG_ID} --output json
        aws ec2 authorize-security-group-ingress --group-id ${currentNodeSG} --protocol tcp --port 22 --source-group ${CLUSTER_SG_ID} --output json
        aws ec2 authorize-security-group-ingress --group-id ${currentNodeSG} --ip-permissions IpProtocol=tcp,FromPort=1025,ToPort=65535,UserIdGroupPairs="[{GroupId=$CLUSTER_SG_ID}]" --output json
        aws ec2 authorize-security-group-ingress --group-id ${CLUSTER_SG_ID} --ip-permissions IpProtocol=-1,FromPort=-1,ToPort=-1,UserIdGroupPairs="[{GroupId=$CLUSTER_SG_ID}]" --output json
        aws ec2 authorize-security-group-ingress --group-id ${currentNodeSG} --ip-permissions IpProtocol=-1,FromPort=-1,ToPort=-1,UserIdGroupPairs="[{GroupId=$currentNodeSG}]" --output json
        aws ec2 authorize-security-group-ingress --group-id ${CLUSTER_SG_ID} --protocol tcp --port 443 --source-group ${currentNodeSG} --output json

    fi 
done

echo 'eks NodeGroup 생성 종료'