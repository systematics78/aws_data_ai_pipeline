
# 📘 Extended Services — Best Practices, Troubleshooting & RCA

This document complements the core ingestion and ML pipeline by providing practices for additional AWS services critical in regulated Data & AI workloads.

---

## 🔥 EMR — Elastic MapReduce (Spark Processing)

### ✅ Best Practices
- Use **auto-termination** after jobs complete
- Create **security configurations** with encryption (S3 + local disks)
- Store logs to **S3 for RCA**
- Always use **EMR roles** with Glue/LF access

### 🚨 Common Issues
| Symptom                    | Possible Cause                             |
|---------------------------|--------------------------------------------|
| Step fails immediately     | Bootstrap action error, invalid S3 path    |
| Job hangs at INIT          | No internet/NAT in subnet                  |
| Cannot write to S3         | Role lacks `s3:PutObject` or KMS access    |

### 🔍 RCA Tips
- Review `/var/log/` logs from master node
- Check subnet route tables + security groups
- Check IAM role policy for `s3`, `kms`, `glue`

---

## 📊 Athena — Serverless SQL over S3

### ✅ Best Practices
- Enable **partition projection** to improve performance
- Always set `QueryResultLocation`
- Use **database+table scoping** in queries

### 🚨 Common Issues
| Symptom                    | Possible Cause                             |
|---------------------------|--------------------------------------------|
| `HIVE_PARTITION_SCHEMA_MISMATCH` | Partition schema drift                 |
| `Table not found`         | Wrong DB context or table dropped          |
| Empty query result        | Misaligned S3 path, wrong partition filter |

### 🔍 RCA Tips
- Inspect table definition in Glue Catalog
- Validate partition keys in S3
- Use `SHOW CREATE TABLE` for schema

---

## 🔒 Lake Formation

### ✅ Best Practices
- Use **LF-Tags** for row/column-level access
- Enable **Lake Formation cross-account audit**
- Delegate administration carefully

### 🚨 Common Issues
| Symptom                    | Possible Cause                             |
|---------------------------|--------------------------------------------|
| User can't access table    | Missing LF permission or tag mismatch      |
| Crawler can't update       | Role not registered in LF                  |

### 🔍 RCA Tips
- Use `GetEffectivePermissionsForPath`
- Check **Lake Formation permissions tab**
- Audit permissions with `LFPermissionsAudit` view

---

## 🛡 IAM / KMS — Identity & Encryption

### ✅ Best Practices
- Assign **separate IAM roles per function** (Glue, SageMaker, EMR)
- Rotate **KMS keys yearly**
- Use **CMKs (not AWS-managed)** for regulated data

### 🚨 Common Issues
| Symptom                    | Possible Cause                             |
|---------------------------|--------------------------------------------|
| `AccessDeniedException`   | SCP, KMS deny, missing trust policy        |
| `KMS key not found`       | Key alias mismatch or deleted              |

### 🔍 RCA Tips
- Run `aws kms describe-key` and validate region
- Review SCPs, Org-wide policies, STS roles
- Use `IAM Policy Simulator`

---

## 📈 Monitoring Stack (CloudTrail, CloudWatch, SNS)

### ✅ Best Practices
- Set retention period to **at least 7 years**
- Use **metric filters** for known error codes
- Send alarms via **SNS to Ops + Compliance**

### 🚨 Common Issues
| Symptom                    | Possible Cause                             |
|---------------------------|--------------------------------------------|
| No logs for failures       | Logging not enabled, role lacks permission |
| Missed alerts              | SNS not subscribed, metric not configured  |

### 🔍 RCA Tips
- Check `cloudtrail` for `PutObject`, `StartJobRun`, `InvokeEndpoint`
- Review `LogGroup` retention and filters
- Test SNS subscriptions with manual publish

---

> 🔐 Ensure all logs are immutable and centrally managed in accordance with GxP/CSV policies.
