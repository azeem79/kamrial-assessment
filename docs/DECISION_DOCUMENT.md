# Architectural Decision Document & Trade-offs

## Executive Summary
This document records the core architectural decisions, technology selections, trade-offs, and design rationales for the **Kamrial Assessment Infrastructure**. The architecture balances operational simplicity, strict security controls, and cost efficiency while demonstrating production readiness.

---

## 1. CI/CD & Deployment Architecture

### Decision
Implement a two-stage GitHub Actions workflow (`.github/workflows/ci.yml`) separating Continuous Integration (CI) and Continuous Deployment (CD).

### Details
1. **Continuous Integration (CI):**
   - **Automated Testing:** Executes mandatory Python `unittest` suite (`app/test_app.py`) to validate application code prior to container creation.
   - **Infrastructure Validation:** Executes `terraform fmt -check` and `terraform validate` to enforce IaC standards.
   - **Security Scanning:** Runs Aquasecurity Trivy directly against local Docker container builds to detect High/Critical image vulnerabilities.

2. **Continuous Deployment (CD):**
   - **Authentication:** Authenticates to AWS via secure GitHub Secrets and OpenID Connect (OIDC).
   - **Container Registry:** Builds and pushes tag-versioned (`${{ github.sha }}`) and `:latest` images to Amazon ECR (`kamrial-api` and `kamrial-worker`).
   - **ECS Deployment:** Dynamically renders task definitions (`terraform/task-definitions/api.json` and `worker.json`) and deploys updates to ECS Fargate services (`kamrial-api-service`, `kamrial-worker-service`).
   - **Stability Verification:** Enforces `wait-for-service-stability: true` to confirm task health before completing deployments.

---

## 2. Infrastructure as Code (IaC) Framework

### Decision
Use **Terraform** to manage 100% of the AWS infrastructure.

### Rationale
- Declarative state management enables auditability and reproducible provisioning.
- Native AWS provider support for VPC, ECS Fargate, RDS PostgreSQL, ALB, and Secrets Manager.

---

## 3. Container Orchestration & Infrastructure Strategy

### Decision: AWS ECS Fargate vs. Kubernetes (EKS)
- **Selection:** AWS ECS Fargate.
- **Rationale:** Minimizes operational overhead by eliminating worker node management, OS patching, and control plane maintenance.
- **Future Trigger for EKS:** Shift to EKS only if application microservices expand beyond 15 distinct domain services or require complex service mesh topology (e.g., Istio).

---

## 4. Observability & Alerting Strategy

### Implemented Controls
- **Centralized Logging:** AWS CloudWatch Logs (`/ecs/kamrial`) with 14-day retention policy.
- **Container Metrics:** ECS CPU Utilization CloudWatch Alarm (`kamrial-ecs-high-cpu`).
- **Queue Metrics:** CloudWatch Metric Alarm (`kamrial-rabbitmq-queue-depth-high`) tracking pending queue messages.
- **Health Checks:** ALB HTTP target group health checks (`/` endpoint, 15s interval, 3-strike failure limit).

### Custom Metric Exporter Architecture
- Standard ECS task CloudWatch logs do not emit application-layer broker queue metrics natively.
- **Production Implementation Path:** RabbitMQ queue depth metrics are pushed to the `Kamrial/RabbitMQ` namespace via the CloudWatch Agent container sidecar or standard Prometheus RabbitMQ Exporter.

---

## 5. Security & Administrative Access

### Implemented Controls
- **Network Isolation:** Internet -> Public ALB -> Private ECS Fargate -> Private RDS PostgreSQL.
- **Secrets Management:** Master database credentials stored and managed via AWS Secrets Manager with IAM least-privilege policies.
- **Administrative Access:** Fargate tasks run as unprivileged non-root containers without host SSH access.

---

## 6. Multi-Environment & Staging Strategy

### Decision
A single environment footprint is provisioned in baseline Terraform execution, with environment parameterization (`var.environment`) fully implemented.

### Rationale & Trade-off
- **Risk Identified:** `RISK_ASSESSMENT.md` highlights lack of environment isolation (dev/staging/prod) as an operational risk.
- **Resolution Strategy:** Rather than provisioning duplicate, cost-incurring cloud resources for a static assessment evaluation, the infrastructure is engineered for multi-environment deployment via **Terraform Workspaces** and parameterized variables (`var.environment`).
- **Production Trigger:** Spawning a dedicated `staging` environment requires executing `terraform workspace new staging && terraform apply -var="environment=staging"`, maintaining total IaC reusability without idle cloud costs.

---

## Summary Matrix

| Domain | Implemented Solution | Justification |
| :--- | :--- | :--- |
| **CI/CD** | GitHub Actions + ECR + ECS Deploy | Automated test, scan, build, push, and rolling update |
| **Orchestration** | AWS ECS Fargate | Serverless execution, zero node management overhead |
| **Database** | Private AWS RDS PostgreSQL | High reliability, managed backups, isolated SGs |
| **Secrets** | AWS Secrets Manager | Eliminates plaintext credentials in code/repos |
| **Testing** | Automated Python `unittest` | Enforces code validity prior to container build |
| **Staging Strategy**| Terraform Workspaces (`var.environment`) | Multi-environment capable without idle AWS costs |