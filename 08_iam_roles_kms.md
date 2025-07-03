## IAM & KMS — Identity & Encryption
AM & KMS Configuration for Secure AWS Data & AI Pipelines

1. 🎯 Purpose in Drug Development
In regulated environments like drug development, IAM and KMS are critical to:
Enforce least-privilege access across users, roles, and services
Ensure data confidentiality and integrity
Comply with GxP, 21 CFR Part 11, and internal audit requirements
Control access to sensitive clinical, omics, and patient data

2. 🔗 Key Dependencies
All AWS services in your pipeline (S3, Glue, Athena, EMR, SageMaker, Step Functions)
Integration with Lake Formation, CloudTrail, and CloudWatch
Optionally: AWS IAM Identity Center (SSO) with Azure AD or LDAP

3. ⚙️ Configuration Steps
🟣 IAM ROLES
Step 1: Define Roles per Service
Service	                    Role Name	                              Trusted By
S3, Glue, Athena	          DataLakeAccessRole	                    Users or federated apps
Glue Crawler	              GlueCrawlerRole	                        glue.amazonaws.com
EMR	                        EMR_EC2_DefaultRole	                    ec2.amazonaws.com
SageMaker	                  SageMakerExecutionRole	                sagemaker.amazonaws.com
Step Functions	            StepFunctionsExecutionRole	            states.amazonaws.com

Example trust policy (emr-trust-policy.json):


{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}

aws iam create-role \
  --role-name EMR_EC2_DefaultRole \
  --assume-role-policy-document file://emr-trust-policy.json

Attach managed policies:

aws iam attach-role-policy \
  --role-name EMR_EC2_DefaultRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role

Step 2: Define Inline or Custom Policies
Example: Read-only access to S3 bucket with tag condition

{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject"],
    "Resource": "arn:aws:s3:::bayer-datalake/*",
    "Condition": {
      "StringEquals": {
        "aws:ResourceTag/DataType": "clinical"
      }
    }
  }]
}

🟡 KMS (Key Management Service)
Step 3: Create a Customer Managed Key (CMK)

aws kms create-key --description "Clinical Data Key" --key-usage ENCRYPT_DECRYPT
Capture the KeyId from response.

Step 4: Create an Alias

aws kms create-alias \
  --alias-name alias/bayer-clinical-data \
  --target-key-id <KeyId>
Step 5: Set Key Policy (Access Control)
Example: Allow EMR and SageMaker access

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:role/EMR_EC2_DefaultRole",
          "arn:aws:iam::123456789012:role/SageMakerExecutionRole"
        ]
      },
      "Action": [
        "kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"
      ],
      "Resource": "*"
    }
  ]
}

4. 🔐 Governance & Security Best Practices
Use separate IAM roles per workload or service
Avoid wildcard * permissions
Rotate IAM access keys (or prefer roles over keys)
Use KMS key policies + grants, not just IAM policies
Enable CloudTrail logging for all IAM/KMS activity
Use SCPs in AWS Organizations to restrict high-risk services

5. ✅ Validation & Outputs
Use aws sts assume-role to test permissions
Validate key usage in KMS > Monitoring tab
Simulate IAM policies with:
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/GlueCrawlerRole \
  --action-names s3:GetObject

6. 🌱 Optional Enhancements
Use Attribute-based access control (ABAC) with tags
Enable CloudWatch alarms for denied actions or unusual key usage
Use Access Analyzer to detect unintended resource sharing
Integrate with AWS Config to monitor non-compliant IAM/KMS resources

