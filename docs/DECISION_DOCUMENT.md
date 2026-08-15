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

---

## 2. Security Strategy & Least Privilege

- **Secrets Management:** Sensitive keys and passwords are passed dynamically via environment variables or cloud secrets managers—never committed in plaintext.
- **Network Isolation:** Database and background workers reside in isolated private subnets; only the API container/load balancer is publicly accessible.
- **Least Privilege:** Cloud service accounts and database users operate under restricted policies scoped strictly to required resources.

---

## 3. Observability Architecture

- **Health Checks:** Configured HTTP/TCP probes inside Docker Compose and cloud orchestrators for instant auto-healing.
- **Logging:** Container logs aggregated via stdout/stderr to standard logging drivers.
- **Alerting Strategy:** Metric alarms on High CPU/Memory, high 5xx error rates, and queue depth threshold breaches.

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

---

## 5. Cost Estimation & Trade-off Analysis

### Estimated Monthly Cloud Cost (AWS Baseline)
- **Compute (ECS Fargate / EC2 burstable):** ~$30 - $50/mo
- **Database (RDS PostgreSQL t4g.micro / small):** ~$15 - $30/mo
- **Networking & Storage (NAT Gateway, S3, ECR):** ~$15 - $25/mo
- **Total Estimated Baseline:** **~$60 - $105 / month**

---

## 6. Management Architecture Requests Response

| Requested Feature | Implement Now? | Justification / Future Trigger |
| :--- | :---: | :--- |
| **Kubernetes** | ❌ No | Overkill for a 3-tier architecture. Introduces high control plane cost and operational complexity. *Trigger:* Microservices count > 15 or complex service mesh needs. |
| **Second Cloud Provider** | ❌ No | Massive operational complexity and cross-cloud networking overhead. *Trigger:* Strict legal/regulatory multi-cloud mandates. |
| **Full ELK Logging** | ❌ No | High memory footprint and maintenance cost. CloudWatch / Grafana Loki / stdout logging is sufficient today. *Trigger:* Log volume > 100GB/day requiring complex full-text querying. |
| **Multi-Region HA** | ❌ No | Doubles compute/database replication costs and complicates data consistency. *Trigger:* Strict SLA requirement for 99.99% uptime with global user distribution. |