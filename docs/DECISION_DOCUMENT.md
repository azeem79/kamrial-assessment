# Architectural Decisions, Security, and Engineering Trade-Offs

## 1. Initial Technical Assessment & Risk Prioritization

### Identified System Weaknesses
1. **Manual Deployments & Lack of IaC:** Leads to configuration drift and non-reproducible environments.
2. **Secrets in Plaintext:** Secrets stored in files or repo risk exposure.
3. **Outdated Dependencies & Unrestricted Access:** Overly broad IAM/database access increases attack surface.
4. **Lack of Observability & Backup Validation:** Blind spots in runtime failure and risk of permanent data loss.

### Prioritization Strategy
* **Address Immediately:** Implement Infrastructure as Code (Terraform), centralized secrets management (environment variables/Secrets Manager), containerization, and basic CI/CD with automated validation.
* **Postpone:** Complex multi-region setups, automated auto-scaling groups, and dedicated Kubernetes cluster management until traffic demands justify the overhead.

See `docs/RISK_ASSESSMENT.md` for the full weakness-by-weakness reasoning.

---

## 2. Security Strategy & Least Privilege

- **Secrets Management:** Sensitive keys and passwords are passed dynamically via environment variables or cloud secrets managers—never committed in plaintext.
- **Network Isolation:** Database and background workers reside in isolated private subnets; only the API container/load balancer is publicly accessible.
- **Least Privilege:** Cloud service accounts and database users operate under restricted policies scoped strictly to required resources.

See `docs/SECURITY.md` for the full security architecture, including audit logging.

---

## 3. Observability Architecture

- **Health Checks:** Configured HTTP/TCP probes inside Docker Compose and cloud orchestrators for instant auto-healing.
- **Logging:** Container logs aggregated via stdout/stderr to standard logging drivers.
- **Alerting Strategy:** Metric alarms on High CPU/Memory, high 5xx error rates, and queue depth threshold breaches.

See `docs/OBSERVABILITY.md` for the full observability design.

---

## 4. Background Worker Incident Response Plan

### Incident Scenario
*API remains healthy, but the background worker has stopped processing jobs for 20 minutes with a growing queue.*

### Detection & Diagnosis Procedure
1. **Alert Trigger:** Alarm fires on Queue Depth exceeding threshold or Worker process heartbeat missing.
2. **Inspection:** Inspect background worker container logs (`docker compose logs worker` or CloudWatch logs).
3. **Root Cause Analysis:** Check database connection pool limits, deadlock states, memory leaks, or unhandled task exceptions.
4. **Remediation:** Safely restart worker container, flush corrupted queue messages if necessary, and scale worker instances.
5. **Prevention:** Implement worker process auto-restart on exit, dead-letter queues (DLQ) for failing tasks, and retry backoff logic.

Demonstrated with real evidence in `docs/incident_recovery.ps1` and `docs/evidence/incident/incident_recovery_log.txt`.

---

## 5. Cost Estimation & Trade-off Analysis

### Estimated Monthly Cloud Cost (AWS Baseline)
- **Compute (ECS Fargate / EC2 burstable):** ~$30 - $50/mo
- **Database (RDS PostgreSQL t4g.micro / small):** ~$15 - $30/mo
- **Networking & Storage (NAT Gateway, S3, ECR):** ~$15 - $25/mo
- **Total Estimated Baseline:** **~$60 - $105 / month**

See `docs/COST_ESTIMATE.md` for the full baseline vs. high-availability cost breakdown and optimization strategies.

---

## 6. Management Architecture Requests Response

| Requested Feature | Implement Now? | Justification / Future Trigger |
| :--- | :---: | :--- |
| **Kubernetes** | ❌ No | Overkill for a 3-tier architecture. Introduces high control plane cost and operational complexity. *Trigger:* Microservices count > 15 or complex service mesh needs. |
| **Second Cloud Provider** | ❌ No | Massive operational complexity and cross-cloud networking overhead. *Trigger:* Strict legal/regulatory multi-cloud mandates. |
| **Full ELK Logging** | ❌ No | High memory footprint and maintenance cost. CloudWatch / Grafana Loki / stdout logging is sufficient today. *Trigger:* Log volume > 100GB/day requiring complex full-text querying. |
| **Multi-Region HA** | ❌ No | Doubles compute/database replication costs and complicates data consistency. *Trigger:* Strict SLA requirement for 99.99% uptime with global user distribution. |

---

## 7. CI/CD Pipeline Scope Decisions

### Scope Limitation
The automated GitHub Actions workflow currently executes static analysis, Terraform validation, Trivy security scanning, and Docker build verification. It deliberately omits automated application unit testing and automated CD deployment stages.

### Justification & Trigger Conditions
* **Application Test Suites:** Omitted at this stage due to the simplicity of the baseline container services. Automated application unit and integration test stages will be integrated into CI when application business logic complexity increases or service test coverage reaches standard thresholds.
* **Continuous Deployment (CD):** Omitted to enforce manual approval gates for infrastructure state updates and cloud resource changes. Fully automated deployment pipelines will be triggered upon transitioning to multi-environment staging/production topologies or when daily deployment frequency warrants automated deployment strategies (e.g., ECS rolling updates via GitHub Actions AWS deployment tasks).
### CI/CD Deployment Architecture
The pipeline (`.github/workflows/ci.yml`) is structured with clear segregation between Continuous Integration (CI) and Continuous Deployment (CD):

1. **CI Pipeline:** On every pull request and commit, executes Python unit test discovery, Terraform formatting/validation, Trivy vulnerability scanning, and local Docker build verification.
2. **CD Pipeline:** On merged changes to the `main` branch (or via manual `workflow_dispatch` trigger), authenticates securely to AWS, builds multi-stage production images, pushes artifacts to Amazon ECR (`kamrial-api`, `kamrial-worker`), and executes rolling updates to AWS ECS Fargate services with health-check stability verification (`wait-for-service-stability`).