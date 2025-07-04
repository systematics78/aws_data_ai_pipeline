## Terraform Setup for SageMaker CI/CD
### Terraform Setup for SageMaker Pipelines & Model Registry

### 1. 🎯 What This Module Does

This Terraform module sets up:

✅ SageMaker pipeline infrastructure  
✅ Model package group for registry  
✅ IAM roles (pipeline execution + model deployment)  
✅ Optional integration with CodeCommit and CodePipeline  
✅ KMS encryption if needed

### 2. 🧱 Terraform Module Structure

```
terraform/
├── main.tf
├── variables.tf
├── sagemaker_pipeline.tf
├── iam_roles.tf
├── kms.tf (optional)
├── outputs.tf
└── versions.tf
```

### 3. ⚙️ Example: Pipeline Execution Role

**iam_roles.tf**
```hcl
resource "aws_iam_role" "sagemaker_pipeline_execution" {
  name = "SageMakerPipelineExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "sagemaker.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_access" {
  role       = aws_iam_role.sagemaker_pipeline_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}
```

### 4. 📦 Model Registry Setup

**sagemaker_pipeline.tf**
```hcl
resource "aws_sagemaker_model_package_group" "clinical_model_group" {
  model_package_group_name        = "clinical-dropout-risk"
  model_package_group_description = "Registered models for dropout risk prediction"
}
```

### 5. 🔐 Optional: KMS Key for Model Artifact Encryption

**kms.tf**
```hcl
resource "aws_kms_key" "sagemaker_model_key" {
  description             = "KMS key for SageMaker model artifacts"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "sagemaker_model_key_alias" {
  name          = "alias/sagemaker-clinical-models"
  target_key_id = aws_kms_key.sagemaker_model_key.key_id
}
```

Use this KMS key when configuring SageMaker training or endpoint config.

### 6. 🧪 Optional: Trigger CodePipeline from Git Push

**main.tf (partial CodePipeline example)**
```hcl
resource "aws_codepipeline" "sagemaker_pipeline" {
  name     = "sagemaker-cicd-pipeline"
  role_arn = aws_iam_role.codepipeline_service.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName = "clinical-risk-repo"
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.train_and_register.name
      }
    }
  }
}
```

### 7. ✅ Outputs

**outputs.tf**
```hcl
output "pipeline_execution_role_arn" {
  value = aws_iam_role.sagemaker_pipeline_execution.arn
}

output "model_package_group_name" {
  value = aws_sagemaker_model_package_group.clinical_model_group.model_package_group_name
}
```

### 8. 🚀 Usage

```bash
terraform init
terraform plan
terraform apply
```

Then use the `pipeline_execution_role_arn` to run your SageMaker pipeline from Python or CLI.
