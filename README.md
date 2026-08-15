# Kamrial Platform Infrastructure & Assessment Solution

A secure, production-ready, three-tier cloud container platform (API Service, Background Worker, and PostgreSQL Database) built with Infrastructure as Code (Terraform), Docker Compose, GitHub Actions CI/CD, and robust observability.

---

## Key Features & Completed Standards

* **Infrastructure as Code:** Modularized Terraform scripts deploying 33 AWS resources with zero hardcoded defaults or dangling references.
* **Secret & Security Management:** Fully sanitized repository history. Zero plaintext credentials. Environment variables managed via dynamic runtime injection (`.env.example` provided).
* **Automated CI/CD Pipeline:** GitHub Actions workflow executing static analysis, security linting, build checks, and unit tests on every push.
* **Observability & Health Monitoring:** Configured HTTP/TCP health checks, CloudWatch metric alarms, and structured log aggregation across services.
* **Incident Recovery Runbook:** Verified real-world queue drain scenario with documented log evidence restoring processing throughput from 10 to 0 backlog messages.
* **Disaster Recovery & Backup Verification:** Isolated PostgreSQL `pg_dump` backup script and automated container restoration process verifying schema integrity (`system_health_logs`).

---

## Quickstart Guide

### 1. Local Setup
```bash
cp .env.example .env
docker compose up -d --build