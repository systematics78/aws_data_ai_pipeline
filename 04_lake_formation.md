## Lake Formation — Fine-Grained Access
AWS Lake Formation Configuration

1. 🎯 Purpose in Drug Development
AWS Lake Formation adds fine-grained governance over your S3 data lake by:

Controlling who can access specific tables, columns, or even rows

Managing centralized permissions on top of Glue Catalog

Enabling data masking and auditing — critical for GxP, PII, and clinical trial access control

This is essential in regulated domains like pharma, where role-specific access is required for data scientists, clinical teams, regulatory affairs, etc.

2. 🔗 Key Dependencies
AWS Glue Data Catalog (see 02_glue_catalog.md)

- S3 bucket (see 01_s3_data_lake.md)
- IAM roles with lakeformation:*, glue:*, s3:GetObject
- KMS key for encryption (optional but recommended)
- Lake Formation administrator permissions

3. ⚙️ Configuration Steps
Step 1: Enable Lake Formation
Go to Lake Formation Console → click “Get started” → opt in.

Step 2: Register S3 Locations as Data Lake Locations

aws lakeformation register-resource \
  --resource-arn arn:aws:s3:::bayer-datalake \
  --use-service-linked-role
(You must be LF Admin to register resources.)


Step 3: Assign Lake Formation Permissions
You define access at the:
- Database level (e.g., full access)
- Table level (read/write)
- Column level (e.g., mask PII)
- Row level (via data filters)

aws lakeformation grant-permissions \
  --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/ClinicalAnalyst \
  --permissions "SELECT" \
  --resource '{
      "Table": {
          "DatabaseName": "clinical_trials",
          "Name": "patients"
      }
  }'

Step 4: Enable Column- or Row-Level Security (Optional)
Define Data Filter (Row-Level Filtering)

aws lakeformation create-data-cell-filter \
  --table-name patients \
  --database-name clinical_trials \
  --name "germany-only" \
  --row-filter '{"AllRowsWildcard": {}, "ColumnNames": ["trial_site"], "FilterExpression": "trial_site = '\''Germany'\''"}'

Assign filter to role:
aws lakeformation grant-permissions \
  --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/RegulatoryTeam \
  --permissions "SELECT" \
  --resource '{
    "DataCellsFilter": {
      "TableCatalogId": "123456789012",
      "DatabaseName": "clinical_trials",
      "TableName": "patients",
      "Name": "germany-only"
    }
  }'

4. 🔐 Governance & Security
- Lake Formation becomes the policy enforcement point for Athena, Redshift Spectrum, and EMR.
- Use tag-based access control (LF-TBAC) for scalable governance.
- Centralize permissions in Lake Formation instead of IAM where possible.
- Audit all access via CloudTrail.

5. ✅ Validation & Outputs
Test in Athena:
- From a user assuming the ClinicalAnalyst role, query the patients table.
- You should only see the allowed rows/columns based on LF permissions.

Check:
aws lakeformation list-permissions

Use the Lake Formation Console to visualize permissions.

6. 🌱 Optional Enhancements
- Enable LF-TBAC (tag-based permissions) for scalable enterprise-wide governance
- Integrate Active Directory groups via IAM Identity Center
- Use CloudTrail Insights to monitor unauthorized access attempts

