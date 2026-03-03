# Artifactory Permission Model

This document describes two high-level permission approaches: **Permission Targets** (classic) and **Project Roles** (project-based), both in a Dev / Test / Release environment model.

---

## 1. High-Level Artifactory Permission Matrix (Permission Target)

Role-based access when using Artifactory **Permission Targets** (Admin → Security → Permission Targets) in a Dev / Test / Release model.


| Role                       | Dev Repository         | Test Repository          | Release Repository       | Notes                                                                      |
| -------------------------- | ---------------------- | ------------------------ | ------------------------ | -------------------------------------------------------------------------- |
| **Developer**              | Read + Deploy          | Read                     | Read                     | Deploy only to Dev                                                         |
| **CI Server**              | Read + Deploy + Delete | Read + Deploy + Annotate | Read + Deploy + Annotate | Pipeline promotions; annotate after promotion (e.g. `UI-Test-Passed=True`) |
| **Release Engineer**       | Read                   | Read                     | Read + Deploy + Annotate | No delete in Release                                                       |
| **Security Team**          | Read                   | Read                     | Read                     | Audit and compliance                                                       |
| **Platform Administrator** | Full Control           | Full Control             | Full Control             | —                                                                          |


---

## 2. High-Level Artifactory Permission Matrix (Project Roles)

Repository access control using JFrog **Predefined Project Roles** in a Dev / Test / Release environment. Anonymous access is disabled globally.

### Overview

Goals:

- **Least privilege** — minimal permissions per role
- **Environment segregation** — Dev / Test / Release boundaries
- **Immutable release** — no delete in Release
- **Audit traceability** — read-only for audit roles
- **Separation of duties** — release vs. development vs. security

### Repository Environments


| Environment | Purpose                        |
| ----------- | ------------------------------ |
| **Dev**     | Active development             |
| **Test**    | QA and integration validation  |
| **Release** | Production; immutable releases |


### Project Role Permission Matrix


| Project Role         | Dev Repositories         | Test Repositories | Release Repositories     | Typical Responsibility            |
| -------------------- | ------------------------ | ----------------- | ------------------------ | --------------------------------- |
| **Project Admin**    | Full Control             | Full Control      | Full Control             | Project resources, repos, members |
| **Developer**        | Read + Deploy            | Read              | Read                     | Day-to-day development            |
| **Contributor**      | Read + Deploy + Annotate | Read + Deploy     | Read                     | CI integration, advanced dev      |
| **Release Manager**  | Read                     | Read              | Read + Deploy + Annotate | Production releases               |
| **Security Manager** | Read                     | Read              | Read                     | Governance and compliance         |
| **Viewer**           | Read                     | Read              | Read                     | Read-only audit and visibility    |
| **AppTrust Manager** | Read                     | Read              | Read                     | Release trust and distribution    |


