## SageMaker CI/CD
CI/CD for Amazon SageMaker (Model Training to Deployment)

#1. 🎯 Purpose in Drug Development
In GxP-regulated environments, SageMaker CI/CD ensures:
  Automated, traceable ML model lifecycle (train → register → approve → deploy)
  Version control for all artifacts (code, data, models)
  Compliance with 21 CFR Part 11 via approvals and audit logs
  Reproducibility for scientific and regulatory audits

#2. 🔗 Key Dependencies
S3: Source code, data, models
SageMaker Pipelines: Orchestration engine
SageMaker Model Registry: Tracks model versions
CodePipeline / CodeBuild (optional)
IAM Role: SageMakerPipelineExecutionRole
Optional: EventBridge, SNS, CloudWatch

#3. ⚙️ Configuration Steps
Step 1: Prepare the Project Structure (in CodeCommit or GitHub)
sagemaker-pipeline/
├── preprocessing.py
├── train.py
├── evaluate.py
├── pipeline.py       # defines Pipeline object
├── config/
│   └── parameters.json
└── buildspec.yml     # (for CodeBuild)

Step 2: Define Pipeline with SageMaker SDK
Install:
pip install sagemaker==2.100 boto3

Sample: pipeline.py

from sagemaker.workflow.pipeline import Pipeline
from sagemaker.workflow.steps import ProcessingStep, TrainingStep, ModelStep
from sagemaker.workflow.parameters import ParameterString, ParameterFloat
from sagemaker.workflow.model_step import RegisterModel
from sagemaker.workflow.pipeline_context import PipelineSession

-- Step 1: Parameters
model_approval = ParameterString(name="ModelApprovalStatus", default_value="PendingManualApproval")

-- Step 2: Training
train_step = TrainingStep(
    name="TrainModel",
    estimator=xgb_estimator,
    inputs={...}
)

-- Step 3: Register
model_metrics = ...
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


Run:

pipeline.upsert(role_arn="arn:aws:iam::123456789012:role/SageMakerPipelineExecutionRole")
pipeline.start(parameters={"ModelApprovalStatus": "PendingManualApproval"})

#Step 3: Track and Approve Model in Registry
Go to SageMaker Console > Model Registry

Select your ModelPackage

Add manual approval (or automate via EventBridge/SNS)

Step 4: Deploy Approved Model (automated or manual)
Once approved:
sagemaker.deploy(
  model_package_arn=model_package_arn,
  initial_instance_count=1,
  instance_type="ml.m5.large",
  endpoint_name="dropout-risk-prod"
)
Step 5: Optional – CI/CD with CodePipeline + CodeBuild
buildspec.yml:

yaml
Copy
Edit
version: 0.2
phases:
  install:
    commands:
      - pip install sagemaker boto3
  build:
    commands:
      - python pipeline.py
Trigger from Git push → CodePipeline → CodeBuild → update SageMaker pipeline

4. 🔐 Governance & Security
Enable CloudTrail for all pipeline and model registry actions
Approvals tracked in Model Registry logs
Use KMS for model artifact encryption
Restrict CreateModel and UpdateEndpoint to only after approvals

5. ✅ Validation & Outputs
SageMaker Console shows pipeline execution graphs
Registered models tracked with version number and approval status
Endpoint updated only after approved model is pushed
Logs in CloudWatch and audit in CloudTrail

6. 🌱 Optional Enhancements
Use EventBridge rule to auto-approve after evaluation metric is good
Integrate with Jira for human-in-the-loop approval
Use Model Monitor to detect drift post-deployment
Use GitHub Actions for repo-triggered pipeline updates

