## SageMaker — ML Training & Inference
Amazon SageMaker Configuration

1. 🎯 Purpose in Drug Development
Amazon SageMaker provides a fully managed platform for:

Training machine learning models using trial or omics data

Deploying inference endpoints for clinical risk scoring, dropout prediction, adverse event detection

Tracking experiments, model versions, and feature sets in a regulated, auditable way

It is ideal for pharma ML pipelines where traceability, versioning, and reproducibility are required under GxP or R&D workflows.

2. 🔗 Key Dependencies
S3 buckets to store training data and model artifacts

IAM roles with SageMaker permissions

VPC (for secure training/inference if needed)

Optional: Glue Catalog for structured feature access via Athena

Optional: CloudWatch, S3 logging, KMS encryption

3. ⚙️ Configuration Steps
Step 1: Create IAM Role for SageMaker
Attach policies:

AmazonSageMakerFullAccess

AmazonS3ReadOnlyAccess

(Optional) AWSGlueConsoleFullAccess if using Athena for training input

aws iam create-role \
  --role-name SageMakerExecutionRole \
  --assume-role-policy-document file://sagemaker-trust-policy.json
Step 2: Upload Data to S3
bash
Copy
Edit
aws s3 cp clinical_features.csv s3://bayer-datalake/processed/ml/
Step 3: Launch Notebook or Training Job
Option A: Studio or Notebook Instance
Create via SageMaker Console → “Notebook” → choose kernel (Python)

Set role = SageMakerExecutionRole

Option B: Launch Training Job (Script in S3)

aws sagemaker create-training-job \
  --training-job-name dropout-model-train \
  --algorithm-specification TrainingImage=382416733822.dkr.ecr.eu-central-1.amazonaws.com/xgboost:1.3-1,TrainingInputMode=File \
  --input-data-config '[
    {
      "ChannelName": "train",
      "DataSource": {
        "S3DataSource": {
          "S3DataType": "S3Prefix",
          "S3Uri": "s3://bayer-datalake/processed/ml/",
          "S3DataDistributionType": "FullyReplicated"
        }
      },
      "ContentType": "csv"
    }
  ]' \
  --output-data-config S3OutputPath=s3://bayer-datalake/models/dropout_xgb \
  --resource-config InstanceType=ml.m5.xlarge,InstanceCount=1,VolumeSizeInGB=30 \
  --stopping-condition MaxRuntimeInSeconds=600 \
  --role-arn arn:aws:iam::<account>:role/SageMakerExecutionRole
Step 4: Deploy Model as Endpoint

aws sagemaker create-model \
  --model-name dropout-model \
  --primary-container Image="...",ModelDataUrl=s3://bayer-datalake/models/dropout_xgb/output/model.tar.gz \
  --execution-role-arn arn:aws:iam::<account>:role/SageMakerExecutionRole

aws sagemaker create-endpoint-config \
  --endpoint-config-name dropout-config \
  --production-variants '[
    {
      "VariantName": "AllTraffic",
      "ModelName": "dropout-model",
      "InitialInstanceCount": 1,
      "InstanceType": "ml.m5.large"
    }
  ]'

aws sagemaker create-endpoint \
  --endpoint-name dropout-inference \
  --endpoint-config-name dropout-config
4. 🔐 Governance & Security
  Enable VPC mode for both training and inference
  Enable KMS encryption for:
  Data at rest (S3)
  EBS volumes
  Model output
  Limit IAM permissions (no open *)
  Use CloudWatch Logs, CloudTrail, and S3 Object Lock for traceability
  Use SageMaker Experiments to track model lineage

5. ✅ Validation & Outputs
Inference call:

aws sagemaker-runtime invoke-endpoint \
  --endpoint-name dropout-inference \
  --body '{"features": [72, 1, 0.85]}' \
  --content-type application/json \
  output.json
Output:
{ "risk_score": 0.87 }
Check logs in CloudWatch: /aws/sagemaker/Endpoints/dropout-inference

6. 🌱 Optional Enhancements
  Use SageMaker Pipelines for full CI/CD
  Register models in Model Registry
  Monitor drift with Model Monitor
  Use Feature Store if features are reused across models
  Trigger retraining via Step Functions
