# Initial Technical Assessment

## Context
The current platform consists of an API, a PostgreSQL database, and a background worker, deployed manually with no infrastructure-as-code, no environment separation, secrets stored in plain configuration files, broad and unaudited access permissions, minimal monitoring, and backups that have never been validated by an actual restore. This document identifies the major risks in that setup, prioritizes them, and explains the reasoning behind those priorities — not as a best-practices checklist, but as an assessment of which failures are most likely, most damaging, and cheapest to fix relative to their impact.

---

## Severity Classification

| # | Weakness | Severity | Priority |
|---|---|---|---|
| 1 | Secrets stored in plain config files | High | Fix immediately |
| 2 | Overly broad / unaudited access permissions | High | Fix immediately |
| 3 | No dev/staging separation | High | Fix immediately |
| 4 | Manual, undocumented deployments | High | Fix immediately |
| 5 | Backups never validated by restore | Medium-High | Fix immediately |
| 6 | Worker failures go undetected | Medium | Fix immediately (cheap, high value) |
| 7 | Minimal monitoring/alerting | Medium | Partial now, expand later |
| 8 | Potentially outdated/vulnerable dependencies | Medium | Address via process, not one-time audit |
| 9 | No IaC / infra not reproducible | Medium | Started now, matured later |

---

## Reasoning: What to Fix Immediately

Secrets in config files and broad permissions are grouped together because they compound each other. A leaked or over-broadly-readable config file is only a low-severity mistake if the credential it holds is narrowly scoped; today, that's not the case — DB credentials likely grant far more access than the API actually needs. The moment either weakness is exploited on its own, the other turns it into a full data-layer compromise rather than a contained incident. Fixing credential scope (least privilege) and secret storage (a secrets manager instead of a file) together removes that multiplier effect for roughly the same amount of work as fixing either one alone, which is why both jump to the top regardless of how "likely" a leak feels in isolation.

No dev/staging separation and manual deployment are also linked. Manual deployment is risky on its own — human error, no rollback path, no audit trail of what changed — but it becomes considerably more dangerous because there's no staging environment to catch mistakes before they reach the only environment that exists. Untested changes go straight to production by definition. Neither problem is expensive to start fixing (a second environment via IaC, and a CI pipeline that at least validates and logs deploys), so the cost-to-risk-reduction ratio here is high, which is why both are addressed now rather than deferred.

Unvalidated backups are treated as high-priority despite being "just" operational hygiene, because an untested backup is not actually a backup — it's an assumption. The failure mode isn't diagnosed until the moment recovery is needed, which is the worst possible time to discover it doesn't work. The fix (a scripted restore into a clean environment) is cheap and fast relative to the cost of discovering a broken backup during a real outage, so this is fixed now rather than postponed.

Worker failure detection is included in the immediate list not because it's severe on its own, but because it's cheap. A stalled worker with a healthy API is a silent failure mode — nothing crashes, nothing alerts, customer-facing symptoms (unprocessed jobs) show up before infrastructure symptoms do. Basic detection here (health checks, queue depth visibility) is low-effort and disproportionately valuable, which is why it's prioritized ahead of more elaborate monitoring work.

---

## Reasoning: What to Postpone, and Why

Full observability (dashboards, alerting stack, distributed tracing) is postponed beyond basic health checks and log visibility. At the current scale — a small system with one API, one DB, one worker — the failure modes are few enough that container health checks, structured logs, and manual inspection during an incident are sufficient to detect and diagnose most problems. Building a full alerting/dashboarding stack now would spend effort on infrastructure to observe complexity the system doesn't yet have. The trigger condition for revisiting this is growth in either traffic or team size: once more than one person needs shared visibility, or once failure modes multiply beyond what a health check can catch, the cost of building proper observability becomes justified by the cost of not having it.

A full dependency audit is deferred in favor of an ongoing process. A one-time audit of "outdated/vulnerable dependencies" produces a report that starts going stale the day it's written. The higher-leverage fix is adding automated dependency/vulnerability scanning into CI, so the system catches new issues continuously rather than requiring a repeated manual pass. This is prioritized as a process change over an immediate one-time fix because it solves the problem permanently for close to the same initial effort.

Fully mature infrastructure-as-code (multiple environments, modules, remote state, full parity between environments) is postponed in favor of a minimal but real version now. The immediate goal is reproducibility and a second environment to de-risk deployment — not a fully productionized Terraform setup with workspaces, modules, and remote state locking. That maturity is valuable but not urgent at current team size; it's the kind of investment that pays off as the team and deployment frequency grow, so it's named explicitly as a next step rather than skipped silently.

---

## Summary of Prioritization Logic

The guiding principle throughout is: fix what compounds risk and what's cheap to fix now; defer what only pays off at a scale or team size the system hasn't reached yet. Secrets, permissions, environment separation, and deployment process are prioritized because leaving them unfixed doesn't just carry risk on its own — it makes every other weakness on this list more dangerous. Backup validation and worker-failure detection are prioritized because they're cheap relative to the cost of discovering they were missing during an actual incident. Full observability, a one-time dependency audit, and mature multi-environment IaC are postponed because their value scales with team size and system complexity that don't yet justify the additional overhead — with explicit conditions named for when that calculus changes.