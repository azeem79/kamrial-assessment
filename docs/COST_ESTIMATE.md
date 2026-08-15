# Monthly Cloud Infrastructure Cost Estimate (AWS)

## Minimal Cost Architecture (Base Operational Tier)

| Service | Architecture Specs | Estimated Monthly Cost |
| :--- | :--- | :--- |
| **Compute (API & Worker)** | 2x AWS Fargate Tasks (0.25 vCPU, 0.5 GB RAM) running 24/7 | ~$18.00 |
| **Database** | AWS RDS PostgreSQL (`db.t4g.micro`, Single-AZ, 20GB Storage) | ~$15.00 |
| **Networking & Load Balancing** | AWS Application Load Balancer (ALB) + Free Public Subnets | ~$20.00 |
| **Observability & Secrets** | CloudWatch Logs (5GB retention) + AWS Secrets Manager (2 secrets) | ~$3.50 |
| **Data Transfer / Egress** | Estimated < 10 GB outbound public internet bandwidth | ~$1.00 |
| **Total Estimated Base Cost** | | **~$57.50 / month** |

---

## Production / Scaled Architecture (High Availability Tier)

| Service | Architecture Specs | Estimated Monthly Cost |
| :--- | :--- | :--- |
| **Compute (API & Worker)** | 4x AWS Fargate Tasks across 2 Availability Zones | ~$36.00 |
| **Database** | AWS RDS PostgreSQL (`db.t4g.small`, Multi-AZ, 50GB Storage) | ~$65.00 |
| **Networking & Security** | AWS ALB + 2x NAT Gateways (Multi-AZ private subnets) | ~$70.00 |
| **Observability & Secrets** | Enhanced CloudWatch Metrics, Alarms, and Secrets Manager | ~$10.00 |
| **Total Production Cost** | | **~$181.00 / month** |

---

## Cost Optimization Strategies
1. **Fargate Spot Instances:** Utilize Fargate Spot for non-critical background worker tasks to reduce compute costs by up to 70%.
2. **RDS Savings Plans:** Commit to a 1-year RDS Reserved Instance to cut database base infrastructure costs by 35%.
