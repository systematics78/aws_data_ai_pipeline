
## Monitoring & Audit
### Monitoring, Observability & Audit Logging Configuration

---

## 1. 🎯 Purpose in Drug Development

In regulated industries like pharma, observability and auditability are required for:

- **GxP compliance**
- **21 CFR Part 11 traceability**
- **Data integrity, change control, and pipeline health monitoring**

This module configures:
- **CloudTrail** (audit)
- **CloudWatch** (logs, metrics, alerts)
- **SNS** (notifications)
- Optional: **GuardDuty**, **Config**, and **EventBridge**

---

## 2. 🔗 Key Dependencies

- All AWS services used in pipeline (S3, Glue, EMR, SageMaker, etc.)
- IAM role with `cloudtrail:*`, `logs:*`, `sns:*`, `cloudwatch:*`
- S3 bucket for audit log storage
- SNS topic for alerts

---

## 3. ⚙️ Configuration Steps

### 🟣 CloudTrail — Audit Logging

**Step 1: Create Audit S3 Bucket**
```bash
aws s3api create-bucket --bucket bayer-cloudtrail-logs --region eu-central-1
```
Enable encryption + Object Lock if required by compliance.

**Step 2: Create CloudTrail**
```bash
aws cloudtrail create-trail \
  --name bayer-data-pipeline-audit \
  --s3-bucket-name bayer-cloudtrail-logs \
  --is-multi-region-trail
```
Enable logging:
```bash
aws cloudtrail start-logging --name bayer-data-pipeline-audit
```

---

### 🟡 CloudWatch Logs & Metrics

**Step 3: Enable Logs from Key Services**

| Service      | Log Group Example                         |
|--------------|-------------------------------------------|
| SageMaker    | `/aws/sagemaker/Endpoints/...`            |
| EMR          | `/emr/containers/...`                     |
| Step Functions | `/aws/states/StateMachineName-execution` |
| Lambda       | `/aws/lambda/<function-name>`             |

Ensure each service has proper log delivery role attached.

**Step 4: Set up Metric Alarms**
Example: Alert on failed Step Function executions
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name StepFunctionFailures \
  --metric-name ExecutionsFailed \
  --namespace AWS/States \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:eu-central-1:123456789012:ClinicalOpsAlerts
```

---

### 🟢 SNS — Notifications

**Step 5: Create SNS Topic**
```bash
aws sns create-topic --name ClinicalOpsAlerts
```
**Subscribe email:**
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:eu-central-1:123456789012:ClinicalOpsAlerts \
  --protocol email \
  --notification-endpoint team@bayer.com
```

Use this topic in:
- Step Functions error handlers
- CloudWatch alarms
- Lambda alerts

---

## 4. 🔐 Governance & Security

- Use KMS-encrypted CloudTrail logs
- Restrict audit log access to a central compliance role
- Tag logs and alarms with Environment, Project, DataType
- Use S3 Object Lock for CloudTrail logs if 21 CFR Part 11 applies

---

## 5. ✅ Validation & Outputs

- **Test CloudTrail:**
```bash
aws cloudtrail lookup-events --max-results 5
```

- **Test CloudWatch logs** from a SageMaker inference or EMR job
- **Trigger a failed Step Function** to validate alarm + SNS

---

## 6. 🌱 Optional Enhancements

- Enable **AWS Config** for drift detection and compliance reporting
- Enable **GuardDuty** for continuous security monitoring
- Route alarms to **EventBridge** for remediation workflows
- Use **AWS Security Hub** for unified compliance dashboards
