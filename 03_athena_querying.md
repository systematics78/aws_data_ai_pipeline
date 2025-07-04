## 🔍 Athena — SQL Analytics

### Amazon Athena Configuration

---

## 1. 🎯 Purpose in Drug Development

Amazon Athena is a serverless SQL engine used to query structured and semi-structured data directly from Amazon S3, using Glue Catalog metadata and governed by Lake Formation.

It’s ideal for:
- Ad hoc analysis of clinical datasets
- Querying transformed omics files (e.g., Parquet)
- Building dashboards (e.g., via QuickSight)
- Lightweight reporting in GxP pipelines

---

## 2. 🔗 Key Dependencies

- Glue Catalog (schemas/tables)
- S3 buckets for data and query results
- Lake Formation (for access control)
- IAM role with:
  - `athena:*`
  - `glue:GetDatabase`, `GetTable`, `GetPartition`
  - `s3:GetObject`, `s3:PutObject` (to data + result bucket)

---

## 3. ⚙️ Configuration Steps

### Step 1: Create Athena Results Bucket (mandatory)

Athena stores query results in a dedicated S3 bucket:

```bash
aws s3api create-bucket --bucket bayer-athena-results --region eu-central-1
```

Optional: Apply lifecycle rule to expire results after 7 days.

---

### Step 2: Set the Results Location

In the Athena Console, go to **Settings** → set:

```
Query result location: s3://bayer-athena-results/
```

Or via CLI:

```bash
aws athena update-work-group \
  --work-group primary \
  --configuration-updates '{"ResultConfigurationUpdates":{"OutputLocation":"s3://bayer-athena-results/"}}'
```

---

### Step 3: Test a Query

Run a query on a Glue/LF-governed table:

```sql
SELECT patient_id, age, trial_site
FROM clinical_trials.patients
WHERE trial_site = 'Germany'
LIMIT 20;
```

Using CLI:

```bash
aws athena start-query-execution \
  --query-string "SELECT * FROM clinical_trials.patients LIMIT 10" \
  --query-execution-context Database=clinical_trials \
  --result-configuration OutputLocation=s3://bayer-athena-results/
```

---

## 4. 🔐 Governance & Security

- Access to data is governed by **Lake Formation** — Athena will only return data based on LF permissions (e.g., row/column filters).
- Athena queries appear in **CloudTrail**.
- Encrypt results in S3 via **KMS** if needed:

```bash
aws s3api put-bucket-encryption \
  --bucket bayer-athena-results \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "<kms-key-id>"
      }
    }]
  }'
```

---

## 5. ✅ Validation & Outputs

Check query status:

```bash
aws athena get-query-execution --query-execution-id <id>
```

Check result files in:

```
s3://bayer-athena-results/<query-execution-id>.csv
```

Validate Lake Formation enforcement by logging in as different IAM roles and testing output restrictions.

---

## 6. 🌱 Optional Enhancements

- Enable **Workgroups** to isolate usage per team/project  
- Set query limits, encryption enforcement, and tag propagation  
- Integrate Athena results with **QuickSight** or **SageMaker**
