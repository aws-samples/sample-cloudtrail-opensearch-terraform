# AWS CloudTrail Monitoring with Amazon OpenSearch Service and Terraform

This Terraform configuration deploys a centralized AWS CloudTrail monitoring solution using Amazon OpenSearch Service. It provisions the complete stack including the OpenSearch domain, ingestion pipeline, index lifecycle management, multi-team access control, and automated alerting.

## Architecture

The solution ingests AWS CloudTrail logs from 100+ AWS accounts through the following pipeline:

```
AWS CloudTrail Org Trail -> Amazon S3 Bucket -> Amazon SQS Queue -> Amazon OpenSearch Ingestion Pipeline -> Amazon OpenSearch Service Domain
```

Key features:
- **500 GB/day** ingestion capacity with auto-scaling (2-10 OCUs)
- **7-year retention** with tiered storage (hot -> warm -> cold -> delete)
- **4 team roles** with fine-grained access control and tenant isolation
- **Automated alerting** for AWS CloudTrail tampering events
- **Full Terraform management** of infrastructure and application-layer config

## Quick Start

You only need **3 inputs** to deploy:

```hcl
vpc_id                    = "vpc-0abc123def456789a"
vpc_subnet_ids            = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
cloudtrail_s3_bucket_name = "amzn-s3-demo-bucket-cloudtrail-logs"
```

The module automatically creates:
- AWS IAM admin role for Amazon OpenSearch Service admin user
- Amazon SNS topic for security alerts
- Amazon SQS queues (main + DLQ) for ingestion throttling
- Security groups with least-privilege rules
- OSIS pipeline IAM role
- AWS KMS key for encryption at rest

> **Cost warning:** This solution deploys billable AWS resources including Amazon OpenSearch Service instances (or1.2xlarge), Amazon EBS gp3 volumes, and Amazon OpenSearch Ingestion OCUs. Review the [Amazon OpenSearch Service pricing](https://aws.amazon.com/opensearch-service/pricing/) before deploying. Remember to clean up resources when they are no longer needed to avoid ongoing charges.

## Prerequisites

- AWS account with AWS CloudTrail organization trail configured
- Terraform >= 1.5.0
- AWS CLI configured with appropriate permissions
- Amazon VPC with private subnets (at least 2 for multi-AZ, 3 recommended)
- An existing Amazon S3 bucket where AWS CloudTrail logs are delivered

## File Structure

```
.
├── README.md                    # This file
├── main.tf                      # OpenSearch domain, KMS key, and security groups
├── variables.tf                 # All input variables with validation
├── outputs.tf                   # Resource identifiers and endpoints
├── providers.tf                 # AWS and OpenSearch provider config
├── versions.tf                  # Terraform and provider version constraints
├── data.tf                      # Data sources and locals
├── iam.tf                       # Primary admin IAM role
├── index_template.tf            # AWS CloudTrail index template with mappings
├── ism_policy.tf                # ISM lifecycle policy (tiered storage)
├── access_control.tf            # Roles, role mappings, tenants
├── alerting.tf                  # Amazon SNS topic, tampering detection monitor
├── ingestion.tf                 # Amazon SQS, Amazon S3 notifications, OSIS pipeline
└── terraform.tfvars.example     # Example variable values
```

## Usage

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd sample-cloudtrail-opensearch-terraform
   ```

2. **Create your variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars** with your 3 required values (Amazon VPC ID, subnet IDs, and Amazon S3 bucket name).

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Review the plan:**
   ```bash
   terraform plan
   ```

6. **Apply:**
   ```bash
   terraform apply
   ```

7. **Verify the deployment:**
   1. Check the Terraform outputs:
      ```bash
      terraform output
      ```
   2. Verify the Amazon OpenSearch Service domain is active:
      ```bash
      aws opensearch describe-domain --domain-name cloudtrail-monitoring --query 'DomainStatus.Processing'
      ```
   3. Access OpenSearch Dashboards (requires VPC connectivity):
      ```bash
      echo "Dashboards URL: https://$(terraform output -raw opensearch_dashboards_endpoint)/_dashboards"
      ```

## Required Inputs

| Variable | Description |
|----------|-------------|
| `vpc_id` | Amazon VPC ID for the Amazon OpenSearch Service domain |
| `vpc_subnet_ids` | List of subnet IDs (min 2, one per AZ) |
| `cloudtrail_s3_bucket_name` | Name of existing Amazon S3 bucket with AWS CloudTrail logs |

## Optional Inputs

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS Region |
| `environment` | `production` | Deployment environment |
| `domain_name` | `cloudtrail-monitoring` | Amazon OpenSearch Service domain name |
| `instance_type` | `or1.2xlarge.search` | Node instance type |
| `instance_count` | `3` | Number of data nodes |
| `ebs_volume_size` | `500` | Storage per node (GB) |
| `osis_min_units` | `2` | Min OCUs for ingestion |
| `osis_max_units` | `10` | Max OCUs for ingestion |
| `alert_email_endpoint` | `""` | Email for alert notifications |
| `team_role_arns` | `{}` | Map of team to AWS IAM role ARNs |
| `hot_retention_days` | `90` | Days in hot storage |
| `warm_retention_days` | `365` | Days in warm storage |
| `cold_retention_days` | `2555` | Total days before deletion |

## Outputs

| Output | Description |
|--------|-------------|
| `opensearch_domain_endpoint` | Domain endpoint URL |
| `opensearch_dashboards_endpoint` | Dashboards URL |
| `admin_iam_role_arn` | Created admin IAM role ARN |
| `sns_topic_arn` | Created Amazon SNS topic ARN |
| `sqs_queue_url` | Ingestion Amazon SQS queue URL |
| `osis_pipeline_arn` | Ingestion pipeline ARN |
| `opensearch_role_names` | Map of created team role names |
| `kms_key_arn` | AWS KMS key ARN for encryption at rest |

## Customization

### Adding a new team role

1. Add the role definition to `local.team_roles` in `data.tf`.
2. Add the AWS IAM role ARN to `var.team_role_arns` in your tfvars.
3. Run `terraform apply`.

### Adjusting retention periods

Modify these variables in your tfvars:
- `hot_retention_days` (default: 90)
- `warm_retention_days` (default: 365)
- `cold_retention_days` (default: 2555 / ~7 years)

### Scaling the ingestion pipeline

Adjust `osis_min_units` and `osis_max_units`. Each OCU supports approximately 1.5-2 MB/s of ingestion throughput. Maximum is 96 OCUs per pipeline.

### Receiving alert notifications

Set `alert_email_endpoint` to your security team's email:
```hcl
alert_email_endpoint = "security-team@example.com"
```

## Cleanup

> **Warning:** This operation permanently deletes all AWS CloudTrail logs stored in the Amazon OpenSearch Service domain, including up to 7 years of retention data. Verify that you have exported or backed up any data you need to retain before proceeding.

To destroy all resources:

1. Remove lifecycle protection by commenting out the `prevent_destroy` block in `main.tf`:
   ```hcl
   # lifecycle {
   #   prevent_destroy = true
   # }
   ```

2. Run the destroy command:
   ```bash
   terraform destroy
   ```

This removes the following resources: Amazon OpenSearch Service domain (including Amazon EBS volumes), Amazon OpenSearch Ingestion pipeline, AWS IAM roles and policies, Amazon SQS queues (main and DLQ), Amazon SNS topic, Amazon S3 event notifications, AWS KMS key, Amazon CloudWatch log groups, and security groups.

## Security Considerations

- All data is encrypted at rest using a customer-managed AWS KMS key and in transit (TLS 1.2+)
- Fine-grained access control helps enforce least-privilege per team
- The Amazon OpenSearch Service domain is deployed in an Amazon VPC (no public access)
- Amazon SQS queues use server-side encryption
- Amazon SNS topic uses AWS KMS encryption
- AWS IAM roles follow the principle of least privilege
- AWS CloudTrail tampering is monitored with automated alerts
- Audit logs are published to Amazon CloudWatch Logs with 365-day retention

## Conclusion

This solution provides a production-ready, fully automated approach to centralized AWS CloudTrail monitoring using Amazon OpenSearch Service and Terraform. It addresses common challenges including ingestion at scale, multi-team access control, compliance-driven retention, and automated threat detection.

For further customization, refer to the [Amazon OpenSearch Service documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/) and the [Terraform OpenSearch provider documentation](https://registry.terraform.io/providers/opensearch-project/opensearch/latest/docs).

## Authors

- Jane Doe, AWS Professional Services
- John Stiles, AWS Professional Services
