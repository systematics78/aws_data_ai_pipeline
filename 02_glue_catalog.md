## Glue — Metadata & Catalog
### AWS Glue Data Catalog Configuration

## 1. 🎯 Purpose in Drug Development
The AWS Glue Data Catalog acts as the metadata layer over your S3-based data lake. It lets services like Athena, EMR, Redshift Spectrum, and SageMaker understand:
- What tables exist
- What schema they have
- Where the data lives (S3 path)
- What format (e.g., Parquet, CSV)

This is essential for structured querying, ETL, and governed access to trial data, omics files, or ML features.

## 2. 🔗 Key Dependencies
- S3 bucket for data lake (see 01_s3_data_lake.md)
- IAM roles with glue:*, s3:GetObject, s3:ListBucket
- Optional: Lake Formation enabled for governance
- AWS Region must match S3 location (e.g., eu-central-1)

## 3. ⚙️ Configuration Steps
### Step 1: Create Glue Database
This is like a schema — a namespace for your tables.
aws glue create-database \
  --database-input '{"Name": "clinical_trials", "Description": "GxP data schema"}'

### Step 2: Define a Table (Manually or Crawlers)
### Option A: Manual Table Creation via API or Console
aws glue create-table \
  --database-name clinical_trials \
  --table-input '{
    "Name": "patients",
    "StorageDescriptor": {
      "Columns": [
        {"Name": "patient_id", "Type": "string"},
        {"Name": "age", "Type": "int"},
        {"Name": "visit_date", "Type": "date"}
      ],
      "Location": "s3://bayer-datalake/raw/clinical/",
      "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
      "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
      "SerdeInfo": {
        "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
        "Parameters": { "field.delim": "," }
      }
    },
    "TableType": "EXTERNAL_TABLE"
  }'

### Option B: Use Glue Crawler to Auto-Detect
aws glue create-crawler \
  --name "crawl_clinical_patients" \
  --role "GlueCrawlRole" \
  --database-name "clinical_trials" \
  --targets '{"S3Targets": [{"Path": "s3://bayer-datalake/raw/clinical/"}]}'

Then:
aws glue start-crawler --name crawl_clinical_patients

## 4. 🔐 Governance & Security
 - Assign IAM role with limited S3 + Glue permissions to the crawler/job
 - Enable Glue Data Catalog encryption if handling PII
 - If Lake Formation is enabled:
     - Grant permissions using LF, not Glue console
 - Protect the Glue DB/table metadata using IAM and resource policies

## 5. ✅ Validation & Outputs
View databases:
aws glue get-databases

View tables:
aws glue get-tables --database-name clinical_trials

Preview data via Athena:
SELECT * FROM clinical_trials.patients LIMIT 10;

## 6. 🌱 Optional Enhancements
- Add partitioning (e.g., by trial_site or visit_date) for query speed
- Register Delta Lake tables via Glue if using EMR/Databricks
- Enable Data Catalog encryption with AWS KMS

