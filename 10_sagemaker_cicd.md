# SageMaker CI/CD
## CI/CD for Amazon SageMaker (Model Training to Deployment)

### 1. 🎯 Purpose in Drug Development
In GxP-regulated environments, SageMaker CI/CD ensures:
- Automated, traceable ML model lifecycle (train → register → approve → deploy)
- Version control for all artifacts (code, data, models)
- Compliance with 21 CFR Part 11 via approvals and audit logs
- Reproducibility for scientific and regulatory audits

### 2. 🔗 Key Dependencies
- **S3**: Source code, data, models
- **SageMaker Pipelines**: Orchestration engine
- **SageMaker Model Registry**: Tracks model versions
- **CodePipeline / CodeBuild** (optional)
- **IAM Role**: `SageMakerPipelineExecutionRole`
- **Optional**: EventBridge, SNS, CloudWatch

### 3. ⚙️ Configuration Steps

#### Step 1: Prepare the Project Structure (in CodeCommit or GitHub)
```
sagemaker-pipeline/
├── preprocessing.py
├── train.py
├── evaluate.py
├── pipeline.py       # defines Pipeline object
├── config/
│   └── parameters.json
└── buildspec.yml     # (for CodeBuild)
```

#### Step 2: Define Pipeline with SageMaker SDK
Install required packages:
```bash
pip install sagemaker==2.100 boto3
```

Sample `pipeline.py`:
```python
from sagemaker.workflow.pipeline import Pipeline
from sagemaker.workflow.steps import ProcessingStep, TrainingStep
from sagemaker.workflow.model_step import RegisterModel
from sagemaker.workflow.parameters import ParameterString
from sagemaker.workflow.pipeline_context import PipelineSession

model_approval = ParameterString(name="ModelApprovalStatus", default_value="PendingManualApproval")

train_step = TrainingStep(
    name="TrainModel",
    estimator=xgb_estimator,
    inputs={...}
)

register_step = RegisterModel(
    name="RegisterModel",
    estimator=xgb_estimator,
    model_data=train_step.properties.ModelArtifacts.S3ModelArtifacts,
    content_types=["text/csv"],
    response_types=["text/csv"],
    approval_status=model_approval,
    model_package_group_name="clinical-dropout-risk"
)

pipeline = Pipeline(
    name="ClinicalRiskPipeline",
    parameters=[model_approval],
    steps=[train_step, register_step]
)
```

Run:
```python
pipeline.upsert(role_arn="arn:aws:iam::123456789012:role/SageMakerPipelineExecutionRole")
pipeline.start(parameters={"ModelApprovalStatus": "PendingManualApproval"})
```

#### Step 3: Track and Approve Model in Registry
- Go to **SageMaker Console > Model Registry**
- Select your `ModelPackage`
- Add manual approval (or automate via EventBridge/SNS)

#### Step 4: Deploy Approved Model
```python
sagemaker.deploy(
  model_package_arn=model_package_arn,
  initial_instance_count=1,
  instance_type="ml.m5.large",
  endpoint_name="dropout-risk-prod"
)
```

#### Step 5: Optional – CI/CD with CodePipeline + CodeBuild
Sample `buildspec.yml`:
```yaml
version: 0.2
phases:
  install:
    commands:
      - pip install sagemaker boto3
  build:
    commands:
      - python pipeline.py
```

### 4. 🔐 Governance & Security
- Enable CloudTrail for pipeline + model registry actions
- Approvals tracked in registry logs
- Use KMS for artifact encryption
- Restrict `CreateModel`, `UpdateEndpoint` to post-approval

### 5. ✅ Validation & Outputs
- Pipeline execution graph (SageMaker Console)
- Versioned model with approval status
- Endpoint updates only post-approval
- Logs: CloudWatch / Audit: CloudTrail

### 6. 🌱 Optional Enhancements
- EventBridge for auto-approval after evaluation metric
- Integrate with Jira for manual approvals
- Use Model Monitor post-deployment
- GitHub Actions to auto-update pipeline
