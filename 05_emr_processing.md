## ⚡ EMR — Distributed Spark Processing

### Amazon EMR Configuration (Apache Spark)

---

## 1. 🎯 Purpose in Drug Development

Amazon EMR (Elastic MapReduce) is used for distributed data processing at scale.  
In drug development pipelines, EMR is ideal for:

- Preprocessing large volumes of clinical, omics, or sensor data  
- Running Spark-based data transformations  
- Batch feature engineering for ML models  
- Parallel ETL workflows over terabyte-scale datasets  

---

## 2. 🔗 Key Dependencies

- S3 data lake (see `01_s3_data_lake.md`)  
- Glue Catalog for table definitions  
- Lake Formation (if using fine-grained access)  
- IAM roles:  
  - EC2 instance profile (for worker nodes)  
  - Service role for EMR (`EMR_DefaultRole`)  
- VPC, subnet, security groups  

---

## 3. ⚙️ Configuration Steps

### Step 1: Create EMR Service Role (if not exists)

```bash
aws iam create-role \
  --role-name EMR_DefaultRole \
  --assume-role-policy-document file://emr-trust-policy.json
```

Attach managed policies:

```bash
aws iam attach-role-policy \
  --role-name EMR_DefaultRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole
```

---

### Step 2: Create EMR Cluster (with Spark, Glue, Lake Formation support)

```bash
aws emr create-cluster \
  --name "Bayer-Clinical-ETL" \
  --release-label emr-6.15.0 \
  --applications Name=Spark Name=Hadoop Name=Hive Name=Livy \
  --service-role EMR_DefaultRole \
  --ec2-attributes KeyName=your-key,InstanceProfile=EMR_EC2_DefaultRole \
  --instance-type m5.xlarge \
  --instance-count 3 \
  --use-default-roles \
  --log-uri s3://bayer-datalake/logs/emr/ \
  --configurations file://emr-config.json \
  --bootstrap-actions file://emr-bootstrap.sh \
  --region eu-central-1
```

**emr-config.json** (Glue integration with Hive):

```json
[
  {
    "Classification": "hive-site",
    "Properties": {
      "hive.metastore.client.factory.class": "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
    }
  }
]
```

---

### Step 3: Submit a Spark Job (ETL)

```bash
aws emr add-steps \
  --cluster-id j-XXXXXXX \
  --steps Type=Spark,Name="ETLJob",ActionOnFailure=CONTINUE,Args=[--deploy-mode,cluster,--class,org.example.ETLJob,s3://path-to-your-job.jar]
```

Or use `spark-submit` via SSH:

```bash
spark-submit s3://bayer-etl/jobs/transform_clinical_data.py \
  --input s3://bayer-datalake/raw/clinical/ \
  --output s3://bayer-datalake/curated/clinical/
```

---

## 4. 🔐 Governance & Security

- Workers should run in private subnet with VPC endpoint to S3  
- Use Lake Formation integration for secure Spark access to governed data  
- Attach only required S3 + Glue + Lake Formation permissions to EC2 instance profile  
- Enable at-rest encryption (HDFS, Spark output)  
- EMR logs go to S3 for traceability (`log-uri`)  

---

## 5. ✅ Validation & Outputs

- Check cluster health via **EMR Console**  
- Output data should appear in S3 under `/curated/clinical/`  
- Job logs should be stored under:  
  `s3://bayer-datalake/logs/emr/...`  
- Verify table metadata in Glue reflects transformed data (optional Glue crawler)  

---

## 6. 🌱 Optional Enhancements

- Use **EMR on EKS** for containerized Spark workloads  
- Use **EMR Serverless** for on-demand Spark jobs (no cluster provisioning)  
- Add **autoscaling policies** for cost optimization  
- Use **spot instances** for non-critical jobs  
- Monitor jobs via **CloudWatch Logs** and **Amazon Managed Grafana**  
