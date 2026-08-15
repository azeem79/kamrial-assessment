# Kamrial Platform Infrastructure & Assessment Solution

A secure, production-ready, three-tier cloud container platform (API Service, Background Worker, and PostgreSQL Database) built with Infrastructure as Code (Terraform), Docker Compose, GitHub Actions CI/CD, and robust observability.

---

## Architecture Diagram

  Public Internet
         |
         v
 ALB / API Service (Public Subnet)
       /     \
      v       v
PostgreSQL DB   Background Worker (Private Subnet)

---

## Key Features & Completed Standards
* **Infrastructure as Code:** Modularized Terraform scripts deploying 33 AWS resources.
* **Secret & Security Management:** Fully sanitized repository history. Zero plaintext credentials.
* **Automated CI/CD Pipeline:** GitHub Actions workflow executing tests and security checks.
* **Observability & Monitoring:** Health checks, CloudWatch alarms, and log aggregation.
* **Incident Recovery Runbook:** Verified real-world queue drain scenario.
* **Disaster Recovery:** Isolated PostgreSQL backup script and automated container restoration.

---

## Documentation Index
* **Risk Assessment:** docs/RISK_ASSESSMENT.md
* **Architecture & Trade-Offs:** docs/ARCHITECTURE.md & docs/DECISION_DOCUMENT.md
* **Security Policy:** docs/SECURITY.md
* **Observability:** docs/OBSERVABILITY.md
* **Incident Runbook:** docs/INCIDENT_RECOVERY_RUNBOOK.md
* **Cost Estimate:** docs/COST_ESTIMATE.md

