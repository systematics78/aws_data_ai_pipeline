
# 📘 Best Practices, Troubleshooting & RCA — AWS Data & AI Pipelines

This guide summarizes key reliability, security, and compliance practices for regulated data pipelines using AWS services (S3, Glue, Transfer, SageMaker, EMR).

---

## ✅ Best Practices

### S3 (Storage)
- Enable **versioning** and **Object Lock** (for compliance)
- Use **encryption with KMS** keys (customer-managed preferred)
- Structure folders: `/raw/`, `/curated/`, `/ml-ready/`
- Enable **access logs** and monitor with CloudTrail

### AWS Transfer Family (SFTP)
- Use **IAM role per user** with minimal S3 access
- Use **TLS-only** and strong password/public key auth
- Route S3 writes to a landing zone with lifecycle rules

### AWS Glue
- Maintain a **single source of schema truth** via Glue Catalog
- Partition data properly (`year/month/day`) for performance
- Run crawlers on **delta zones**, not full lake
- Document data formats and schema evolution history

### SageMaker
- Use **Model Registry** for all deployed models
- Include metadata (source data hash, hyperparameters, date)
- Automate training + approval via pipelines
- Limit access to model artifacts using KMS/IAM

### Step Functions
- Add **error handling** with `Catch`, `Retry`, and `TimeoutSeconds`
- Integrate with SNS for failure notifications
- Use **CloudWatch Logs** to capture state transitions

---

## 🚨 Common Issues & Pitfalls

| Issue                             | Service       | Cause / Fix |
|----------------------------------|---------------|-------------|
| `AccessDenied` when uploading    | S3 / Transfer | IAM role lacks `s3:PutObject` or bucket policy |
| Crawler not detecting new files  | Glue          | Wrong path or no new partitions created |
| SageMaker training stuck         | SageMaker     | No available instance quota or input data inaccessible |
| Timeout on model inference       | SageMaker     | Endpoint config needs increase to `MaxConcurrentInvocations` |
| SFTP upload fails intermittently | Transfer      | DNS, public IP, firewall issues or SFTP client config |

---

## 🧰 Troubleshooting Tips

- Use `CloudTrail` to check **PutObject**, `StartJobRun`, `CreateModel` logs
- Use `CloudWatch Logs` for Lambda, Step Function, EMR, and SageMaker jobs
- Query logs via **Athena** for audit or failure analysis
- Use `aws s3api head-object` to confirm file visibility

---

## 📊 RCA Checklist Template

### When a file upload is missing:
- [ ] Was IAM permission granted to write to the bucket?
- [ ] Is bucket policy or SCP blocking access?
- [ ] Is there a version conflict (overwritten file)?
- [ ] Did upload fail silently (check SFTP logs)?
- [ ] Did EventBridge or Lambda trigger downstream logic?

### When Glue job fails:
- [ ] Are input paths correct and accessible?
- [ ] Are schemas mismatched or missing columns?
- [ ] Is temp directory (Glue temp dir in S3) accessible?
- [ ] Do roles have access to KMS key?

### When model fails to deploy or predict:
- [ ] Was the model package approved and deployed?
- [ ] Are input features consistent with training set?
- [ ] Are resource limits (CPU/mem) too low?
- [ ] Are model artifacts deleted or encrypted with unknown KMS?

---

## 🔐 GxP & Audit Compliance

- Always use **CloudTrail** + `Athena` queries to reconstruct events
- For S3: enable **Object Lock + Versioning**
- Ensure logs from **Step Functions, SageMaker, Lambda** are centralized
- Tag all resources (`Environment`, `GxP`, `System`, `DataType`)
- Retain logs for **7–10 years** if required

---

## 📦 Suggested Tools

- `AWS CLI` & `boto3` for scripting
- `Athena` for querying logs
- `Glue Schema Registry` for evolving schemas
- `Step Functions` visual flow for state-level trace

---

> 📌 Use this guide during incident resolution or pre-audit preparation.

