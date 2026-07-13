# Centralized CloudTrail Monitoring with Amazon OpenSearch Service and Terraform

This Terraform configuration deploys a centralized AWS CloudTrail monitoring solution using Amazon OpenSearch Service. It provisions the complete stack including the OpenSearch domain, ingestion pipeline, index lifecycle management, multi-team access control, and automated alerting.

## Architecture

The following diagram shows the architecture of the centralized CloudTrail monitoring solution:

![Architecture Diagram](images/architecture.png)

The solution ingests AWS CloudTrail logs from 100+ AWS accounts through the following pipeline:

**AWS CloudTrail Org Trail → Amazon S3 Bucket → Amazon SQS Queue → Amazon OpenSearch Ingestion Pipeline → Amazon OpenSearch Service Domain**

Key features:
- **200 GB/day** ingestion capacity with auto-scaling (2-10 OCUs)
- **30-day retention** in hot tier (extendable with optional warm/cold tiers)
- **4 team roles** with fine-grained access control and tenant isolation
- **Automated alerting** for AWS CloudTrail tampering events
- **Full Terraform management** of infrastructure and application-layer configuration

## Prerequisites

- An AWS organization with CloudTrail enabled across member accounts
- Terraform v1.5+ with the AWS provider and the OpenSearch provider
- A VPC with private subnets for the OpenSearch domain
- An existing S3 bucket receiving CloudTrail logs from an organization trail
- IAM permissions to create OpenSearch, SQS, SNS, IAM, and KMS resources

## Quick Start

You only need **3 inputs** to deploy:

```hcl
vpc_id                    = "vpc-0abc123def456789a"
vpc_subnet_ids            = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
cloudtrail_s3_bucket_name = "my-org-cloudtrail-logs"
```

### Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply
```

The module automatically creates:
- OpenSearch domain (6x or1.4xlarge data nodes, 3x r6g.large dedicated masters)
- Amazon SQS queues (main + DLQ) for ingestion throttling
- Amazon OpenSearch Ingestion pipeline (auto-scales 2-10 OCUs)
- Index template with CloudTrail field mappings
- ISM policy for automated rollover and retention
- Fine-grained access control with 4 team roles and tenant isolation
- CloudTrail tampering detection monitor with SNS alerting
- Security groups, IAM roles, and KMS keys

## Configuration

### Required Variables

| Variable | Description |
|----------|-------------|
| `vpc_id` | VPC ID for the OpenSearch domain |
| `vpc_subnet_ids` | List of subnet IDs (one per AZ, minimum 2) |
| `cloudtrail_s3_bucket_name` | S3 bucket containing CloudTrail logs |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `domain_name` | `cloudtrail-monitoring` | OpenSearch domain name |
| `engine_version` | `OpenSearch_3.3` | OpenSearch engine version |
| `instance_type` | `or1.4xlarge.search` | Data node instance type |
| `instance_count` | `6` | Number of data nodes |
| `number_of_shards` | `6` | Primary shards per index |
| `number_of_replicas` | `0` | Replica count (0 for OR1 with S3 durability) |
| `rollover_size` | `30gb` | Rollover at primary shard size |
| `rollover_age` | `1d` | Rollover at index age |
| `hot_retention_days` | `30` | Days in hot tier before deletion |
| `alert_email_endpoint` | `""` | Email for SNS alert notifications |
| `team_role_arns` | `{}` | Map of team names to IAM role ARNs |

See `variables.tf` for the complete list with descriptions and validation rules.

## Architecture Details

### OpenSearch Domain

- **Instance type:** or1.4xlarge (storage-optimized, EBS-backed with S3 segment replication)
- **Data nodes:** 6 (across 3 availability zones)
- **Dedicated masters:** 3x r6g.large
- **Encryption:** At rest (KMS), in transit (TLS 1.2+), node-to-node
- **Access:** Fine-grained access control with IAM-based authentication

### Ingestion Pipeline

- **Source:** Amazon S3 via SQS notifications
- **Auto-scaling:** 2-10 OCUs based on queue depth
- **Format:** Gzip-compressed JSON CloudTrail logs
- **DLQ:** Dead letter queue for failed messages (3 retries)

### Index Lifecycle (ISM Policy)

- **Rollover:** When primary shard reaches 30 GB OR index age reaches 1 day
- **Retention:** 30 days in hot tier, then delete
- **Optional:** Extended policy with warm/cold tiers for 7-year compliance (see `ism_policy.tf`)

### Access Control

Four team roles with tenant isolation:
- **security_ops:** Full read + alert management
- **incident_response:** Full read for investigation
- **compliance_auditors:** Read-only
- **devops:** Infrastructure metrics + limited CloudTrail

### Alerting

- CloudTrail tampering detection (StopLogging, DeleteTrail, etc.)
- Alerts via Amazon SNS (email subscription configurable)

## Extending with Cold Storage

For organizations requiring longer retention (e.g., 7 years for PCI DSS or HIPAA), an extended ISM policy with warm and cold tiers is included as a commented-out alternative in `ism_policy.tf`. Uncomment and configure as needed.

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.

## Related Resources

- [Amazon OpenSearch Service Documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/)
- [OpenSearch Optimized Instances (OR1)](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/or1.html)
- [Amazon OpenSearch Ingestion](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ingestion.html)
- [Index State Management](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ism.html)
- [Fine-grained Access Control](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html)
- [Terraform AWS Provider - OpenSearch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain)
- [Terraform OpenSearch Provider](https://registry.terraform.io/providers/opensearch-project/opensearch/latest/docs)
