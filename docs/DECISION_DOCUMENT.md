---

## CI/CD Pipeline Scope Decisions

### Scope Limitation
The automated GitHub Actions workflow currently executes static analysis, Terraform validation, Trivy security scanning, and Docker build verification. It deliberately omits automated application unit testing and automated CD deployment stages.

### Justification & Trigger Conditions
* **Application Test Suites:** Omitted at this stage due to the simplicity of the baseline container services. Automated application unit and integration test stages will be integrated into CI when application business logic complexity increases or service test coverage reaches standard thresholds.
* **Continuous Deployment (CD):** Omitted to enforce manual approval gates for infrastructure state updates and cloud resource changes. Fully automated deployment pipelines will be triggered upon transitioning to multi-environment staging/production topologies or when daily deployment frequency warrants automated deployment strategies (e.g., ECS rolling updates via GitHub Actions AWS deployment tasks).