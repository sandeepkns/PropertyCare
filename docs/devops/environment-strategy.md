# PropertyCare Environment Strategy Matrix

| Environment | Org Type | Target Use Case / Git Branch Tracking |
| :--- | :--- | :--- |
| **Dev** | Disposable Scratch Org (`pc-dev`) | Active isolated feature branch engineering (`feature/*`) |
| **QA** | Scratch Org / Sandbox | Automated CI Pull Request validation targets (`PR-Check`) |
| **UAT** | Dedicated Sandbox Org | User Acceptance Testing, staging, and final stakeholder demo runs |
| **Prod / Demo** | Dev Hub Org / Agentforce Host | The "Live" target production environment and Agentforce host (`main`) |

## Environment Lifespan Rules
* **Scratch Orgs are ephemeral**: Delete them the second a feature branch is merged or abandoned. 
* **Reproducibility Requirement**: Any developer must be able to spin up a fully operational development environment from scratch by running your Phase 0 setup script coupled with your Phase 15 `seed.apex` data generator.