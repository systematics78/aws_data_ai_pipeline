## Step Functions — Pipeline Orchestration
### AWS Step Functions Configuration

## 1. 🎯 Purpose in Drug Development
AWS Step Functions enables you to build orchestrated, auditable workflows across AWS services.
In drug development, it can automate:
- ETL flows across EMR → SageMaker → S3 → SNS
- Clinical data risk analysis (e.g., if dropout risk > threshold, trigger alert)
- Batch ML pipelines with human approval or branching logic
- GxP-compliant automation with traceable state transitions and error handling

## 2. 🔗 Key Dependencies
- EMR cluster (optional)
- SageMaker model/inference endpoint
- IAM role with:
  - `states:*`
  - `lambda:*, emr:*, sagemaker:*, sns:*, glue:*` (as needed)
- Input/output data in S3
- Optional: SNS topic for notifications

## 3. ⚙️ Configuration Steps

### Step 1: Create IAM Role for Step Functions
```bash
aws iam create-role   --role-name StepFunctionsExecutionRole   --assume-role-policy-document file://stepfn-trust-policy.json
```

Attach policies:
```bash
aws iam attach-role-policy   --role-name StepFunctionsExecutionRole   --policy-arn arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess
```

And any service-specific policies required (AmazonSageMakerFullAccess, etc.)

### Step 2: Define State Machine JSON

Example: EMR → SageMaker → Risk Threshold → Notify (SNS)
```json
{
  "Comment": "Clinical Risk Workflow",
  "StartAt": "StartEMRJob",
  "States": {
    "StartEMRJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::elasticmapreduce:addStep.sync",
      "Parameters": {
        "ClusterId": "j-XXXXXXX",
        "Step": {
          "Name": "ETL Step",
          "ActionOnFailure": "CONTINUE",
          "HadoopJarStep": {
            "Jar": "command-runner.jar",
            "Args": ["spark-submit", "s3://bayer-etl/jobs/etl.py"]
          }
        }
      },
      "Next": "InvokeModel"
    },
    "InvokeModel": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sagemaker:invokeEndpoint.sync",
      "Parameters": {
        "EndpointName": "dropout-inference",
        "Body": {
          "features.$": "$.transformed_features"
        },
        "ContentType": "application/json"
      },
      "ResultPath": "$.inference",
      "Next": "CheckRisk"
    },
    "CheckRisk": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.inference.risk_score",
          "NumericGreaterThan": 0.75,
          "Next": "NotifyTeam"
        }
      ],
      "Default": "End"
    },
    "NotifyTeam": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "arn:aws:sns:eu-central-1:123456789012:ClinicalAlerts",
        "Message": "High dropout risk detected",
        "Subject": "Trial Risk Alert"
      },
      "End": true
    },
    "End": {
      "Type": "Pass",
      "End": true
    }
  }
}
```

### Step 3: Create State Machine
```bash
aws stepfunctions create-state-machine   --name ClinicalRiskPipeline   --definition file://risk-pipeline.json   --role-arn arn:aws:iam::<account-id>:role/StepFunctionsExecutionRole
```

### Step 4: Start Execution
```bash
aws stepfunctions start-execution   --state-machine-arn arn:aws:states:eu-central-1:123456789012:stateMachine:ClinicalRiskPipeline   --input file://execution-input.json
```

## 4. 🔐 Governance & Security
- Assign least privilege IAM policies to Step Function role
- Log all executions to CloudWatch Logs
- Enable CloudTrail for auditability
- Use KMS-encrypted SNS topics or data payloads if transmitting sensitive data

## 5. ✅ Validation & Outputs
- View execution graph in Step Functions Console
- Check success/failure in Execution History
- Validate outputs in:
  - SageMaker logs (inference)
  - EMR logs (step success)
  - SNS (alert message received)
  - S3 (processed data written)

## 6. 🌱 Optional Enhancements
- Use Map State for parallel processing (e.g., per patient batch)
- Add human approval steps via Lambda integrations
- Add retry and timeout logic for each service
- Chain to another state machine or notify third-party systems (e.g., ServiceNow)
