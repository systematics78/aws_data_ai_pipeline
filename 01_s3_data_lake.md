## S3 — Data Lake Storage
### Amazon S3 Configuration for Data Lake

## 1. 🎯 Purpose in Drug Development
- Amazon S3 acts as the central data lake for storing:
  - Clinical trial datasets (CSV, Parquet, JSON)
  - Genomics or omics files (VCF, BAM, FASTQ)
- Real-world evidence (RWE) from external partners
- Model artifacts and logs
- S3 provides durability, scalability, versioning, and integration with AWS analytics and ML services.

## 2. 🔗 Key Dependencies
- IAM Roles with fine-grained access
- KMS key (customer-managed if GxP required)
- VPC endpoints (for private access)
- Optional: Lake Formation registration for governance

## 3. ⚙️ Configuration Steps
### Step 1: Create S3 Buckets
Recommended structure:
aws s3api create-bucket --bucket bayer-datalake-<env> --region eu-central-1

Folder layout (prefixes):
<pre>s3://bayer-datalake/
├── raw/               # Ingested, untouched data.
├── curated/           # Cleaned, structured datasets.
├── processed/         # ML-ready or analytics outputs.
├── models/            # Saved ML models.
├── logs/              # ETL/ML job logs. </pre>


### Step 2: Enable Versioning
`aws s3api put-bucket-versioning \
  --bucket bayer-datalake-dev \
  --versioning-configuration Status=Enabled`

### Step 3: Enable Encryption with KMS
Use a customer-managed KMS key:
`aws s3api put-bucket-encryption \
  --bucket bayer-datalake-dev \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "<your-kms-key-id>"
      }
    }]
  }`

### Step 4: Block Public Access (MANDATORY)

`aws s3api put-public-access-block \
  --bucket bayer-datalake-dev \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true`

## 4. 🔐 Governance & Security
- Use S3 bucket policies + IAM conditions (aws:SourceVpc, aws:PrincipalArn)
- Attach resource tags (e.g., Environment=Dev, DataType=Clinical)
- Enable CloudTrail for full access logging
- Use Object Lock (if regulated data requires write-once-read-many, WORM)

For analytics access: prefer S3 Access Points or Lake Formation integration

## 5. ✅ Validation & Outputs
Upload sample file:
`aws s3 cp trial_data.csv s3://bayer-datalake/raw/clinical/`

Confirm versioning:
`aws s3api list-object-versions --bucket bayer-datalake-dev`

Test IAM access with assumed role:
`aws sts assume-role --role-arn arn:aws:iam::<acct>:role/S3Reader --role-session-name test`

## 6. 🌱 Optional Enhancements
- Enable Intelligent-Tiering for cost savings
- Enable access logs to a separate S3 bucket
- Apply lifecycle rules:
  - Archive old raw data to Glacier Deep Archive
  - Expire logs after 180 days
