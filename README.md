# Use S3 to STS AssumeRole to give fine tuned access control to AWS services inter/intra ACCOUNT

This repository creates the S3 bucket, IAM Roles, IAM policy to test Access control using AWS STS access control

# Overview
 AWS AssumeRole allows you to grant temporary credentials with additional privileges to users as needed, following the principle of least privilege. To configure AssumeRole access, you must define an IAM role that specifies the privileges that it grants and which entities can assume it. AssumeRole can grant access within or across AWS accounts. If you are administering multiple AWS accounts, you can use AssumeRole configuration to enable scoped access across accounts without having to manage individual users in each account they may need to interact with resources in.

 The AWS Terraform provider can use AssumeRole credentials to authenticate against AWS. In this tutorial, you will use Terraform to define an IAM role that allows users in one account to assume a role in a second account and provision AWS instances there. You will then configure an AWS provider to use the AssumeRole credentials and deploy an EC2 instance across accounts.

![1](https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole/blob/main/images/assume_role_flow.png)



# Steps
To configure AWS IAM Roles/Policy for Resource provider and user using Terraform
- 
- create S3 bucket as private ()
- create IAM policy to read this private S3 bucket
- create IAM Identity provider with EKS OIDC provider with audience=sts.awsamazon.com
- create IAM Role and attach this IAM S3 Policy
- Create a Service Account with above IAM Role ARN in annotation section of k8s SA (https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole)
- use the Service Account in a pod to access the S3 bucket (https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole)

# Advantages
The IAM roles for service accounts feature provides the following benefits:

(1) Least privilege- By using the IAM roles for service accounts feature, you no longer need to provide extended permissions to the worker node IAM role so that pods on that node can call AWS APIs. You can scope IAM permissions to a service account, and only pods that use that service account have access to those permissions.

(2) Without IRSA, all worker nodes where the pods can be scheduled, should be provided access to AWS service. This is because pods can be
    scheduled dynamically on all the relevant  worker nodes based on their toleration/node affinity rules. This creates broad privelage for 
    all pods on all the worker nodes, access to the AWS service.

(3) Credential isolation- A container can only retrieve credentials for the IAM role that is associated with the service account to which it belongs. A container never has access to credentials that are intended for another container that belongs to another pod.

(4) Auditability- Access and event logging is available through CloudTrail to help ensure retrospective auditing.

# IAM Roles for Service Accounts Technical Overview
AWS IAM supports federated identities using OIDC. This feature allows us to authenticate AWS API calls with supported identity providers and receive a valid OIDC JSON web token (JWT). You can pass this token to the AWS STS AssumeRoleWithWebIdentity API operation and receive IAM temporary role credentials. Such credentials can be used to communicate with services likes Amazon S3 and DynamoDB.

# AWS Documentation
   link : https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/

   Drilling further down into our solution: OIDC federation access allows you to assume IAM roles via the Secure Token Service (STS), enabling authentication with an OIDC provider, receiving a JSON Web Token (JWT), which in turn can be used to assume an IAM role. Kubernetes, on the other hand, can issue so-called projected service account tokens, which happen to be valid OIDC JWTs for pods. Our setup equips each pod with a cryptographically-signed token that can be verified by STS against the OIDC provider of your choice to establish the pod???s identity. Additionally, we???ve updated AWS SDKs with a new credential provider that calls sts:AssumeRoleWithWebIdentity, exchanging the Kubernetes-issued OIDC token for AWS role credentials.

   The resulting solution is now available in EKS, where we manage the control plane and run the webhook responsible for injecting the necessary environment variables and projected volume. The solution is also available in a DIY Kubernetes setup on AWS; more on that option can be found below.

   To benefit from the new IRSA feature the necessary steps, on a high level, are:

   - Create a cluster with eksctl or terraform and OIDC provider setup enabled. This feature works with EKS clusters 1.13 and above.
   - Create an IAM role defining access to the target AWS services, for example S3, and annotate a service account with said IAM role.
   - Finally, configure your pods by using the service account created in the previous step and assume the IAM role.
   - Because the service account has an eks.amazonaws.com/role-arn annotation, the webhook injects the necessary environment variables (AWS_ROLE_ARN and AWS_WEB_IDENTITY_TOKEN_FILE) and sets up the aws-iam-token projected volume in the pod that the job supervises.

   ![2](https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole/blob/main/images/irp-eks-setup-1024x1015.png)
   
# Background
In Kubernetes version 1.12, support was added for a new ProjectedServiceAccountToken feature, which is an OIDC JSON web token that also contains the service account identity, and supports a configurable audience.

Amazon EKS now hosts a public OIDC discovery endpoint per cluster containing the signing keys for the ProjectedServiceAccountToken JSON web tokens so external systems, like IAM, can validate and accept the Kubernetes-issued OIDC tokens.

OIDC federation access allows you to assume IAM roles via the Secure Token Service (STS), enabling authentication with an OIDC provider, receiving a JSON Web Token (JWT), which in turn can be used to assume an IAM role. Kubernetes, on the other hand, can issue so-called projected service account tokens, which happen to be valid OIDC JWTs for pods. Our setup equips each pod with a cryptographically-signed token that can be verified by STS against the OIDC provider of your choice to establish the pod???s identity.

new credential provider ???sts:AssumeRoleWithWebIdentity???

# Preparation

## Spin up EKS cluster using github repo

Repo: https://github.com/bijubayarea/test-terraform-eks-cluster .
This repo is used to spin up EKS Cluster with SPOT EKS managed node group.

## Requirements

To use this repo for demo purposes you will need the following.
- AWS Account (at least one, can do multiple)
- AWS IAM Credentials with admin purposes (for demo)
- AWS IAM Role with adminstrative privileges for Terraform to   assume (multi-account setup)
- AWS S3 Bucket to hold state
- Kubectl installed
- Terraform 0.14.3 installed 
- Basic knowledge of AWS IAM, and Kubernetes components.

## STEPS
    - github to spin up EKS cluster  (https://github.com/bijubayarea/test-terraform-eks-cluster)
    - github to create  (https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole)
        -  IAM role + trusted entity OIDC(EKS cluster's OIDC)
        -  policy to access one S3 bucket 
        -  role-policy attachment, 
        -  create s3 bucket
        -  create ns = irsa-s3-ns
        -  create service account=s3-policy with IAM Role ARN in annotation section.
        -  create deployment with ns/sa and read/write one S3 bucket.


## To spin up
This Repo : https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole

- Add your roles, and account ID's to the variables.tf
- Add your pre-existing S3 State bucket to main.tf

- Run `terraform -chdir=src init`
Which will initialize your workspace and pull any providers needed such as AWS and the Kubernetes providers.

Then run a terraform plan `terraform -chdir=src plan -var 'env=test'`

If looks ok go ahead and run the apply `terraform -chdir=src apply -var 'env=test'`

Answer with yes when asked if you want to apply. It will take a bit to provision the VPC, related resources, the EKS cluster and related resources. Once done you need to setup your local kubectl for access by running `aws eks update-kubeconfig --region us-west-2 --name aws-vpc` or `aws eks update-kubeconfig --region us-west-2 --name aws-vpc --role arn:aws:iam::<account_id>:role/<name>` with whatever role you used to create the cluster (defined in variables).

## Config 

![3](https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole/blob/main/images/irsa-oidc.png)

![4](https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole/blob/main/images/Trusted_Entities.png)


![5](https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole/blob/main/images/s3_policy.png)


## Kubernetes Testing

### GOOD Scenario
  To deploy the demo app with SA=s3-policy to test IRSA ability.
   Run:
  `kubectl apply -f demo_irsa_app/demo_app.yaml --dry-run=client`
  if the dry run looks ok go ahead and apply it.
  `kubectl apply -f demo_irsa_app/demo_app.yaml`
  
  Once deployed you can describe the deployment, service account, etc and see how they are linked up.

  pod with SA=s3-policy get assigned `IAM_ROLE="arn:aws:sts::427234555883:assumed-role/staging-eks-1N3Y9646-s3-policy-role/botocore-session-1666715908"`
  
  
  ```hcl
        $ kubectl get deploy -n irsa-s3-ns
        NAME      READY   UP-TO-DATE   AVAILABLE   AGE
        aws-cli   1/1     1            1           39m5s 
          
          $ kubectl get  pod -n irsa-s3-ns
          NAME                       READY   STATUS    RESTARTS   AGE
          aws-cli-6d86899bb5-s49r9   1/1     Running   0          40m
                 
 
  ```
  
  show assumed Role.
  show JSON WebToken details (JWT)
  ```hcl
        $ k -n irsa-s3-ns exec aws-cli-6d86899bb5-s49r9 -- sh -c 'aws sts get-caller-identity'
{    
        "UserId": "AROAWG6JJ67VTKONEH2XR:botocore-session-1666715908",
        "Account": "427234555883",
        "Arn": "arn:aws:sts::427234555883:assumed-role/staging-eks-1N3Y9646-s3-policy-role/botocore-session-1666715908"
}    
      $ k -n irsa-s3-ns get secrets s3-policy-token-5jrd8  -o jsonpath='{.data.token}' | base64 -d
        eyJhbGciOiJSUzI1NiIsImtpZCI6ImJYVGdrNXVMX3lwdzE1R2pjMGViclhuTUI1cmliV2VmOHV0ZzU3ck8ySm8ifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJpcnNhLXMzLW5zIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6InMzLXBvbGljeS10b2tlbi01anJkOCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJzMy1wb2xpY3kiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI3YTM4M2UxYi0wMDU4LTQ3ZWItYWM0MS0yOWFkMGQ2NjE5NDEiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6aXJzYS1zMy1uczpzMy1wb2xpY3kifQ.pF1QzSEbZxVBXzfUzXwxacT7KEUcQkdHw6wx8713KZGu4HijVjBSPEKFzqEEUQIVPivaKePh8qM8JV3tkjNdIJdo8L2FrTIx-y_FnMmMiDOc4b_RThU7Anpm74t0ouW8OzoFnsIQ6BObldyVdhR4NAofuoMhu45GqLgHkDtqC4p1XCilSN8RUrZ21jJD0AIaLMKYwrFNFBMSRGJ3mSBeh8IjcO3KoFD9NSPpSiVuphgpa7sjWRH2Ktfvs0tXnlDA5uP9Gztr6mwWZvPZiNEKSCRv10dDnsqb5b8nBJmp90d7swS5RNoPiY2MblqAVkqfzG-MH-B7OkdIGf0bBA0sDQ

  ```
  
  JWT Token decoded

  ![6](https://github.com/bijubayarea/bah-terraform-aws-s3-stsAssumeRole/blob/main/images/JWT_decode.png)


  
  Display env varaible injected to pod by mutating webhooks (from SA annotation)
  
  ```hcl
        $ k -n irsa-s3-ns exec aws-cli-6d86899bb5-s49r9 -- sh -c 'echo $AWS_ROLE_ARN'
        arn:aws:iam::427234555883:role/staging-eks-1N3Y9646-s3-policy-role
  
        $ k -n irsa-s3-ns exec aws-cli-6d86899bb5-s49r9 -- sh -c 'echo $AWS_WEB_IDENTITY_TOKEN_FILE'
        /var/run/secrets/eks.amazonaws.com/serviceaccount/token      


        $ k -n irsa-s3-ns exec aws-cli-6d86899bb5-s49r9 -- sh -c env | grep AWS
        AWS_ROLE_ARN=arn:aws:iam::427234555883:role/staging-eks-1N3Y9646-s3-policy-role
        AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
        AWS_DEFAULT_REGION=us-west-2
        AWS_REGION=us-west-2
        AWS_STS_REGIONAL_ENDPOINTS=regional
  
  ```

  upload a file to S3 bucket=`bijubayarea-s3-test-owner`
  
  ```hcl
     $ k exec -n irsa-s3-ns aws-cli-6d86899bb5-s49r9 -- sh -c 'echo "Testing s3 bucket fine-grained access by IAM_ROLE=$AWS_ROLE_ARN" > hello.txt'

     $ k exec -n irsa-s3-ns aws-cli-6d86899bb5-s49r9 -- sh -c 'cat hello.txt'
      Testing s3 bucket fine-grained access by IAM_ROLE=arn:aws:iam::427234555883:role/staging-eks-1N3Y9646-s3-policy-role   

    $ k exec -n irsa-s3-ns aws-cli-6d86899bb5-s49r9 -- sh -c 'aws s3 cp hello.txt s3://bijubayarea-s3-test-owner/'
    upload: ./hello.txt to s3://bijubayarea-s3-test-owner/hello.txt  


     $ k exec -n irsa-s3-ns aws-cli-6d86899bb5-hqb7c -- sh -c 'aws s3 ls s3://bijubayarea-s3-test-owner/'
     2022-10-25 17:12:14        117 hello.txt

  
  ```

## BAD scenario-1

upload file to non-owned S3 bucket(`s3://bijubayarea-s3-test-non-owner`) from POD SA

 
 ```hcl
       $ k exec -n irsa-s3-ns aws-cli-6d86899bb5-s49r9 -- sh -c 'aws s3 cp hello.txt s3://bijubayarea-s3-test-non-owner/'
        upload failed: ./hello.txt to s3://bijubayarea-s3-test-non-owner/hello.txt An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
        command terminated with exit code 1


         
      $ k exec -n irsa-s3-ns aws-cli-6d86899bb5-hqb7c -- sh -c 'aws s3 ls s3://bijubayarea-s3-test-non-owner/'

       An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
       command terminated with exit code 254

  ```

## BAD scenario-2

 Change deployment to `ServiceAccount=default` and test again.
 Pod will assume `Node` Iam role and will not have access to S3 bucket(`s3://bijubayarea-s3-test-owner/`)

 `kubectl apply -f demo_irsa_app/demo_app.yaml`
 
 ```hcl
       $ k -n irsa-s3-ns exec aws-cli-68876cc4d5-hldfx -- sh -c 'aws sts get-caller-identity'
       {
           "UserId": "AROAWG6JJ67VTM6CJBXMB:i-09c7e2b0b7b5f671a",
           "Account": "427234555883",
           "Arn": "arn:aws:sts::427234555883:assumed-role/node-group-1-eks-node-group-20221025152035508900000008/i-09c7e2b0b7b5f671a"
       }


       $ k -n irsa-s3-ns exec aws-cli-68876cc4d5-hldfx -- sh -c env | grep AWS
       <NO ENV varaiable SET>


       $ k exec -n irsa-s3-ns aws-cli-68876cc4d5-hldfx -- sh -c 'aws s3 ls s3://bijubayarea-s3-test-owner/'

       An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
       command terminated with exit code 254
                       
  ```

## Tear Down

Delete any object in s3 buckets. Even if not deleted it is OK, since S3 buckets are provisioned with `force_destroy = true`

 ```hcl
    $ k -n irsa-s3-ns  exec aws-cli-66fbd888cc-28jk5 -- sh -c 'aws s3 rm  s3://bijubayarea-s3-test-owner/hello.txt'
    delete: s3://bijubayarea-s3-test-owner/hello.txt

     `terraform -chdir=src destroy -var 'env=test'`   

  ```
