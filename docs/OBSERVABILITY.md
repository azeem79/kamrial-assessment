# Observability & Monitoring Architecture

## 1. Overview
This document details the observability, log management, health checking, and metrics aggregation strategy designed and provisioned in `terraform/main.tf`.

---

## 2. Centralized Logging Architecture
* **CloudWatch Log Group:** Provisioned via Terraform (`aws_cloudwatch_log_group.ecs`, named `/ecs/kamrial`) with a 14-day retention policy.
* **AWS Logs Driver:** Both ECS task definitions (`api` and `worker`) configure the `awslogs` driver to stream `stdout` and `stderr` directly to `/ecs/kamrial`.
* **Container Log Prefixes:** Formatted under the `ecs` log stream prefix for easy filtering.

---

## 3. Application Health Checks & Load Balancing
* **ALB Target Group Health Checks (`aws_lb_target_group.api`):**
  * **Path:** `/` (HTTP GET)
  * **Interval:** 15 seconds
  * **Timeout:** 5 seconds
  * **Unhealthy Threshold:** 3 consecutive failures
  * **Healthy Threshold:** 2 consecutive successes
* **Automatic Draining:** Unhealthy tasks fail health checks and are replaced automatically by ECS Fargate.

---

## 4. Recommended Alarms & Metrics Strategy
* **Worker Queue Backlog:** Monitor RabbitMQ Queue Depth (> 50 messages threshold).
* **API Error Rate:** Monitor ALB 5xx HTTP response counts.
* **Database Metrics:** Monitor RDS CPU utilization (> 80%) and available storage space (< 5GB).