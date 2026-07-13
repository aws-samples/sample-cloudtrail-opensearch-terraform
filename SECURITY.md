# Security

## Non-Production Disclaimer

This sample code is provided for educational and demonstration purposes only. It is **NOT** intended for direct production deployment without additional security hardening. Review the [Production Hardening](#production-hardening) section below before deploying to a production environment.

## Reporting Vulnerabilities

If you discover a potential security issue in this project, we ask that you notify AWS/Amazon Security via our [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public GitHub issue for security vulnerabilities.

## AWS Services Used

This solution provisions and configures the following AWS services:

| Service | Purpose |
|---------|---------|
| Amazon OpenSearch Service | Search and analytics engine for CloudTrail logs |
| Amazon OpenSearch Ingestion | Serverless data pipeline (S3 to OpenSearch) |
| Amazon S3 | Source of CloudTrail logs (existing bucket) |
| Amazon SQS | Ingestion throttling and event notifications |
| Amazon SNS | Security alert notifications |
| AWS KMS | Customer-managed encryption keys |
| AWS IAM | Roles and policies for least-privilege access |
| Amazon CloudWatch Logs | OpenSearch domain audit and slow logs |
| Amazon VPC | Network isolation for the OpenSearch domain |

## Security Controls Implemented

- **Encryption at rest**: All data stores use customer-managed KMS keys with annual rotation
- **Encryption in transit**: TLS 1.2+ enforced with modern cipher policy (Policy-Min-TLS-1-2-PFS-2023-10)
- **Network isolation**: OpenSearch domain deployed in private VPC subnets with security groups
- **IAM least privilege**: Custom policies scoped to specific resource ARNs
- **Fine-grained access control**: 4 team roles with tenant isolation (no shared dashboard access)
- **Audit logging**: CloudTrail audit logs published to CloudWatch
- **Dead letter queue**: Failed ingestion messages retained for investigation
- **Automated alerting**: CloudTrail tampering detection (StopLogging, DeleteTrail, etc.)

## Known Security Considerations

The following trade-offs were made for sample simplicity. Address these before production deployment:

| Item | Current State | Production Recommendation |
|------|--------------|--------------------------|
| Security group egress | Unrestricted outbound (0.0.0.0/0) | Restrict to VPC endpoints for S3, SQS, CloudWatch, KMS, and STS |
| Terraform provider versions | `~>` range constraints | Commit `.terraform.lock.hcl` for exact version pinning |
| Terraform state | Local state file | Use remote backend (S3 + DynamoDB) with encryption and access control |
| Domain `prevent_destroy` | Enabled | Review based on your lifecycle management strategy |

## Production Hardening

Before deploying to production, implement the following:

1. **Remote Terraform state**: Configure an S3 backend with DynamoDB locking, SSE-KMS encryption, and restricted bucket policies.

2. **Restrict security group egress**: Replace the unrestricted outbound rule with specific VPC endpoint routes:
   ```hcl
   # Example: Allow only HTTPS to VPC endpoints
   resource "aws_security_group_rule" "opensearch_egress_vpc_endpoints" {
     type              = "egress"
     from_port         = 443
     to_port           = 443
     protocol          = "tcp"
     prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
     security_group_id = aws_security_group.opensearch.id
   }
   ```

3. **Pin provider versions**: Run `terraform init` and commit the generated `.terraform.lock.hcl` to your repository for reproducible builds.

4. **Enable AWS Config rules**: Monitor for configuration drift on the OpenSearch domain, KMS keys, and IAM roles.

5. **Add CloudWatch alarms**: Monitor cluster health, storage utilization, and ingestion lag.

6. **Review IAM role trust policies**: Ensure the OpenSearch admin role trust policy is scoped to specific principals rather than the account root.

7. **Enable VPC Flow Logs**: Capture network traffic metadata for the VPC hosting the OpenSearch domain.

## Resource Cleanup

To remove all resources created by this module:

```bash
terraform destroy
```

**Important**: Verify that you have exported any data, dashboards, or saved searches before destroying. The `prevent_destroy` lifecycle rule on the OpenSearch domain will block destruction unless removed first:

```hcl
# Temporarily remove to allow destroy
lifecycle {
  # prevent_destroy = true
}
```

After running `terraform destroy`, verify the following are removed:
- OpenSearch domain and all indices
- KMS keys (scheduled for deletion after the configured window)
- SQS queues and dead letter queue
- SNS topics and subscriptions
- IAM roles and policies
- Security groups
- CloudWatch Log Groups
