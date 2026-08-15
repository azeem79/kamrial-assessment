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
## 5. Architectural Trade-Off Analysis

### Scenario 1: Container Orchestration (Kubernetes vs. AWS ECS/Fargate)
* **Decision:** Selected AWS ECS / AWS Fargate over Kubernetes (EKS).
* **Rationale:** For a three-tier setup (API, Worker, PostgreSQL), Kubernetes introduces excessive control plane overhead ($73/month per EKS cluster base) and operational complexity (ingress controllers, CNI plugins, RBAC management). ECS/Fargate provides serverless container execution with zero cluster management overhead, automatic IAM role integration, and native scaling.
* **When to Pivot to K8s:** Migration to EKS is justified only if service count expands beyond ~15 microservices, requires cloud-agnostic deployment specs (Helm), or demands complex mesh networking (Istio/Envoy).

### Scenario 2: Multi-Cloud vs. Single-Cloud Strategy
* **Decision:** Primary deployment restricted strictly to single-cloud (AWS).
* **Rationale:** Multi-cloud deployments exponentially increase infrastructure cost, cross-cloud egress fees, identity management complexity, and latency. AWS native tooling (Terraform AWS provider, RDS, CloudWatch, Secrets Manager) allows maximum velocity and minimal operational headcount.
* **Risk Mitigation:** Infrastructure is fully defined in standard Terraform modules with containerized workloads, allowing re-platforming to GCP or Azure within days if business continuity dictates.

### Scenario 3: Centralized Logging & Observability (Self-Hosted ELK vs. Managed CloudWatch/Datadog)
* **Decision:** Standardized on AWS CloudWatch + Container stdout/stderr streaming over self-hosted ELK (Elasticsearch/Logstash/Kibana).
* **Rationale:** Self-hosting an ELK stack requires running resource-intensive Elasticsearch nodes (minimum 3x `t3.medium` instances for quorum) costing $100+/month in maintenance and storage overhead. Native CloudWatch log groups provide pay-per-ingest model with zero cluster management.
* **Production Recommendation:** At higher scale (>50GB logs/day), adopt Datadog or Grafana Cloud rather than self-hosted ELK to preserve DevOps velocity.

### Scenario 4: High Availability & Multi-Region Strategy
* **Decision:** Multi-AZ deployment within a single primary AWS region (e.g., `us-east-1a` and `us-east-1b`).
* **Rationale:** Multi-region active-active deployments require complex cross-region database replication (Aurora Global Database / DynamoDB Global Tables) and asynchronous conflict resolution, costing 3x-4x more. Multi-AZ provides 99.95% uptime for regional/datacenter failures at minimal extra cost.
