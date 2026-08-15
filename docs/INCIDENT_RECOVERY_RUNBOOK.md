# Incident Recovery Runbook

## Objective
To simulate a service outage within the containerized stack and demonstrate rapid incident recovery.

---

## Architecture Self-Healing Mechanisms
- **Docker Compose Restart Policies:** Containers configured with `restart: always` or `unless-stopped` will automatically reboot upon unexpected failure.
- **Health Checks:** Configured health checks ensure unhealthy containers are flagged for restart.

---

## Incident Simulation Steps

### 1. Execute Recovery Script
Run the automated recovery simulation script from the root directory:

```powershell
.\docs\incident_recovery.ps1