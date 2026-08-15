# Kamrial Platform Infrastructure & Assessment Solution

A secure, production-ready, three-tier cloud container platform (API Service, Background Worker, and PostgreSQL Database) built with Infrastructure as Code (Terraform), Docker Compose, GitHub Actions CI/CD, and robust observability.

---

## Key Features & Completed Standards

* **Infrastructure as Code:** Modularized Terraform scripts deploying 33 AWS resources with zero hardcoded defaults or dangling references.
* **Secret & Security Management:** Fully sanitized repository history. Zero plaintext credentials. Environment variables managed via dynamic runtime injection (`.env.example` provided).
* **Automated CI/CD Pipeline:** GitHub Actions workflow executing Terraform validation, a Trivy security scan, and Docker build tests on every push.
* **Observability & Health Monitoring:** Configured HTTP/TCP health checks, CloudWatch metric alarms, and structured log aggregation across services.
* **Incident Recovery Runbook:** Verified real-world queue drain scenario with documented log evidence restoring processing throughput from a 10-message backlog to 0.
* **Disaster Recovery & Backup Verification:** Isolated PostgreSQL `pg_dump` backup script and automated container restoration process verifying schema integrity (`system_health_logs`).

---

## Quickstart Guide

### 1. Local Setup

```bash
cp .env.example .env
# edit .env and set POSTGRES_PASSWORD to any value for local dev
docker compose up -d --build
```

### 2. Services

| Service | Address |
|---|---|
| API | `http://localhost:8000` |
| RabbitMQ management UI | `http://localhost:15672` (default guest/guest) |
| PostgreSQL | `localhost:5432` (db `kamrial_db`, seeded via `app/init.sql`) |

---

## Infrastructure as Code

`terraform/` provisions the AWS equivalent of the local stack: VPC with public/private subnets, NAT gateway, tiered security groups (ALB → App → DB), an ALB + target group, RDS PostgreSQL with an AWS-managed master password, ECR repositories, an ECS cluster, and ECS services/task definitions for both the API and worker, with CloudWatch logging wired in.

```bash
cd terraform
terraform init
terraform plan
```

---

## CI/CD
> **Pipeline Note:** Historical workflow runs reflect iterative development, security hardening, and pipeline troubleshooting. The current main branch reflects the fully validated, production-ready CI/CD implementation.
`.github/workflows/ci.yml` runs on every push/PR to `main`: Terraform format/validate, a Trivy security scan, and Docker build tests for both the API and worker images.

---

## Documentation Index

| Doc | Covers |
|---|---|
| [`docs/RISK_ASSESSMENT.md`](docs/RISK_ASSESSMENT.md) | Initial weaknesses, severity, and prioritization reasoning |
| [`docs/SECURITY.md`](docs/SECURITY.md) | Network isolation, secrets management, IAM, vulnerability scanning |
| [`docs/OBSERVABILITY.md`](docs/OBSERVABILITY.md) | Logging, health checks, and alerting strategy |
| [`docs/DECISION_DOCUMENT.md`](docs/DECISION_DOCUMENT.md) | Consolidated trade-offs and the Kubernetes/multi-cloud/ELK/multi-region judgment question |
| [`docs/COST_ESTIMATE.md`](docs/COST_ESTIMATE.md) | Baseline vs. HA monthly AWS cost breakdown and optimization strategies |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | System diagram and component responsibilities (single source of truth for the diagram) |
| [`docs/INCIDENT_RECOVERY_RUNBOOK.md`](docs/INCIDENT_RECOVERY_RUNBOOK.md) | The worker-failure incident scenario, how to run it, and prevention follow-ups |

---

## Incident Recovery Demonstration

Simulates the worker stalling while the API stays healthy — detection (queue depth + container state), diagnosis (worker logs), and recovery (restart + backlog drain).

```powershell
pwsh ./docs/incident_recovery.ps1
```

Evidence from the last verified run is in `docs/evidence/incident/incident_recovery_log.txt`, showing the backlog building to 10 messages while the worker was down and draining back to 0 after recovery.

---

## Backup & Restore Demonstration

Takes a `pg_dump` of the live database, restores it into a freshly provisioned, isolated PostgreSQL container (not the same running instance), and verifies the schema and data landed correctly before tearing the test container down.

```powershell
pwsh ./docs/db_backup_restore.ps1
```

Evidence from the last verified run is in `docs/evidence/backup/backup_restore_log.txt`, confirming the `system_health_logs` table is present and queryable in the restored, isolated database.

---

## Security Notes

- No credentials are committed to this repository or its git history. Local secrets are supplied via a gitignored `.env` file (see `.env.example` for the required keys).
- RDS uses an AWS-managed master password (`manage_master_user_password`) rather than a stored credential.
- See `docs/SECURITY.md` for the full network and IAM design.
