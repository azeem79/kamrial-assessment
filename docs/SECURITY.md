# Security & Threat Model Architecture

## 1. Executive Summary
This document outlines the security controls, identity management, threat mitigations, and secret handling strategy applied across the infrastructure and application lifecycle.

---

## 2. Network Isolation & Boundary Security
* **VPC Isolation:** Public subnets host only the Application Load Balancer (ALB) and NAT Gateway. All ECS Fargate containers and RDS database instances are deployed strictly in private subnets with `assign_public_ip = false`.
* **Security Group Tiering:**
  * **ALB SG:** Accepts inbound HTTP (80) from `0.0.0.0/0`.
  * **App SG:** Accepts inbound traffic on port 8000 ONLY from the ALB SG.
  * **DB SG:** Accepts inbound traffic on PostgreSQL port 5432 ONLY from the App SG.

---

## 3. Secret Management & Credential Safety
* **Zero Hardcoded Passwords:** No database passwords or master credentials exist in Terraform code, environment variables, or committed repository files.
* **AWS Secrets Manager Integration:** RDS master password is managed automatically via `manage_master_user_password = true`.
* **IAM Secret Fetching:** ECS Task Execution Role is explicitly granted `secretsmanager:GetSecretValue` permissions mapped directly to `aws_db_instance.postgres.master_user_secret[0].secret_arn`. Passwords are injected at container startup via ECS secrets mapping (`DB_PASSWORD`).

---

## 4. Identity & Access Management (IAM)
* **Least Privilege Execution:** Tasks run under an isolated execution role configured strictly with `AmazonECSTaskExecutionRolePolicy` and a scoped Secrets Manager read policy.
* **No Direct Host Access:** Fargate eliminates container-to-host lateral movement threats by managing underlying infrastructure.

---

## 5. Vulnerability Scanning & CI/CD Security
* **Automated IaC Security Scanning:** GitHub Actions runs Trivy scanning on all Terraform configurations to detect misconfigurations prior to merge.
* **Container Image Hygiene:** Images built in CI undergo vulnerability checks prior to deployment.

---

## 6. Audit Logging & Compliance Monitoring
* **AWS CloudTrail Integration:** AWS CloudTrail is designated to capture management and data events across all AWS account API activities. Every request — whether originating from IAM users, Terraform provisioning runs, or automated ECS execution roles — is logged for audit trail and forensic readiness.
* **Network & Access Auditing:** VPC Flow Logs capture IP traffic entering and leaving network interfaces across the public and private subnets, ensuring full visibility into inbound and egress network patterns.