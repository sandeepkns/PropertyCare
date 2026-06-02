## A. The five logical layers

| Layer | Responsibility | Key components | Built in |
|---|---|---|---|
| **Agent (AI) layer** | Tenant-facing intake & queries | Agentforce agent / LWC chat, 3 invocable Apex actions | Phase 7 |
| **Event layer** | Decouple intake from processing | `Service_Request__e`, event trigger, async work-order creation, retry/DLQ | Phase 5, 6, 14 |
| **Integration layer** | Bidirectional sync with external portal/vendor | Inbound JWT REST, outbound Named Credential + Queueable | Phase 10, 11, 12 |
| **Security layer** | Tenant data isolation & access control | OWD Private, sharing, FLS (`stripInaccessible`), Connected App/JWT, permission sets | Phase 4 |
| **Observability layer** | Visibility & alerting | `Integration_Log__c`, LWC monitoring console, DLQ alert | Phase 13 |

---

## B. High-level component diagram

```mermaid
flowchart TB
    subgraph EXT["External (free-tier host)"]
        PORTAL["Tenant Portal<br/>Node.js + Express"]
    end

    subgraph AGENT["Agent Layer"]
        AF["Agentforce Agent<br/>(or LWC chat fallback)"]
        ACT["Invocable Apex Actions<br/>BookSlot · RequestStatus · GenerateSOA"]
    end

    subgraph EVENT["Event Layer"]
        SR["Service_Request__c<br/>(OWD Private)"]
        PE["Service_Request__e<br/>(Platform Event)"]
        ETRIG["Event Trigger<br/>SLA + Work Order"]
        WO["Work_Order__c<br/>(CDC enabled)"]
        DLQ["Failed_Event__b<br/>(Big Object DLQ)"]
        REPLAY["Schedulable Batch<br/>Replayer"]
    end

    subgraph INTEG["Integration Layer"]
        REST["Apex REST<br/>/api/v1/service-requests<br/>(JWT bearer)"]
        QCALL["Queueable Callout<br/>Named Credential"]
    end

    subgraph BILLING["Billing"]
        CDC["CDC on Work_Order__c"]
        SOA["Billing_Statement__c<br/>(SOA)"]
    end

    subgraph OBS["Observability Layer"]
        LOG["Integration_Log__c"]
        CONSOLE["LWC Monitoring Console"]
        ALERT["DLQ Threshold Alert<br/>(email / Slack webhook)"]
    end

    PORTAL -->|"inbound JWT"| REST
    REST --> SR
    AF --> ACT
    ACT --> SR
    SR -->|publish| PE
    PE --> ETRIG
    ETRIG --> WO
    ETRIG -.->|on failure| DLQ
    REPLAY -.->|retry| PE
    WO --> CDC
    CDC --> SOA
    WO -->|status sync| QCALL
    QCALL -->|"outbound Named Cred"| PORTAL
    QCALL --> LOG
    REST --> LOG
    LOG --> CONSOLE
    DLQ --> ALERT
    ACT -->|status query| WO
```

---

## C. Sequence diagram — happy path (request → work order → vendor sync)

```mermaid
sequenceDiagram
    participant T as Tenant
    participant A as Agent / Portal
    participant SR as Service_Request__c
    participant PE as Service_Request__e
    participant TR as Event Trigger (async)
    participant WO as Work_Order__c
    participant CDC as CDC
    participant SOA as Billing_Statement__c
    participant Q as Queueable Callout
    participant V as External Portal/Vendor
    participant L as Integration_Log__c

    T->>A: "Book a repair"
    A->>SR: insert Service_Request__c
    SR->>PE: publish Service_Request__e
    Note over SR,PE: insert commits, event fires after commit
    PE->>TR: deliver event (async)
    TR->>WO: create Work_Order__c + assign SLA
    WO->>CDC: change event
    CDC->>SOA: upsert billing/SOA record
    WO->>Q: enqueue status sync
    Q->>V: callout via Named Credential
    V-->>Q: 200 OK
    Q->>L: log success (status, latency)
    V-->>A: later: status update (inbound JWT REST)
    A->>WO: update status
```

---

## D. Sequence diagram — failure & retry (dead-letter path)

```mermaid
sequenceDiagram
    participant PE as Service_Request__e
    participant TR as Event Trigger
    participant WO as Work_Order__c
    participant DLQ as Failed_Event__b
    participant SCH as Schedulable Replayer
    participant L as Integration_Log__c

    PE->>TR: deliver event
    TR->>WO: attempt work-order creation
    alt processing fails (e.g. DML / lock / limit)
        TR->>DLQ: persist event payload + reason + attempt=1
        TR->>L: log failure
    end
    Note over SCH: runs on schedule (e.g. hourly)
    SCH->>DLQ: query rows where attempts < MAX
    SCH->>PE: re-publish event
    alt success on retry
        SCH->>DLQ: mark resolved
    else still failing
        SCH->>DLQ: increment attempts
        alt attempts >= MAX
            SCH->>L: flag for manual review + alert
        end
    end
```

---

## E. Sequence diagram — agent action with security & guardrails

```mermaid
sequenceDiagram
    participant T as Tenant
    participant AG as Agent
    participant ACT as Invocable Apex Action
    participant SEC as Security (sharing + FLS)
    participant DB as Salesforce Data

    T->>AG: "What's the status of request SR-123?"
    AG->>ACT: invoke RequestStatus(requestId, tenantContext)
    ACT->>SEC: query with "with sharing" + stripInaccessible
    SEC->>DB: SOQL scoped to tenant's own records
    alt record belongs to tenant
        DB-->>ACT: record
        ACT-->>AG: status
    else not found / not owned
        ACT-->>AG: "No request found for your account"
        Note over ACT,AG: never reveal another tenant's data;<br/>never fabricate an ID
    end
    alt low model confidence
        AG->>AG: escalate to human queue
    end
```

---

## F. Data flow diagram — billing propagation via CDC

```mermaid
flowchart LR
    WO["Work_Order__c<br/>Status changes"] -->|Change Data Capture| CDCEVT["WorkOrderChangeEvent"]
    CDCEVT --> CDCTRIG["CDC Apex Trigger"]
    CDCTRIG -->|map status -> billing state| SOA["Billing_Statement__c"]
    CDCTRIG -->|log| LOG["Integration_Log__c"]
    SOA -->|reused by| SOAACT["GenerateSOA agent action"]
```

---

## G. Deployment / environment topology

```mermaid
flowchart LR
    DEV["Local VS Code<br/>SFDX source"] -->|push| GH["GitHub<br/>main + feature branches"]
    GH -->|PR validation| CI["GitHub Actions<br/>tests + PMD gate"]
    CI -->|deploy| SCRATCH["Scratch Org<br/>pc-dev"]
    GH -->|manual/agent work| DEVHUB["Dev Hub Org<br/>(Agentforce host)"]
    DEV -->|node deploy| HOST["Free-tier host<br/>Tenant Portal"]
```

---

## H. Architectural decisions recorded here (full ADRs written in Phase 19)

These are the decisions the diagrams encode; note them now so Phase 19's ADR files just expand them:

1. **Platform Event between request and work order** (not direct DML in the agent action) — decouples intake latency from processing, enables retry/DLQ.
2. **Queueable for callouts** (not `@future`, not trigger-direct) — chaining, better limits, testable, keeps DML and callouts separated.
3. **Big Object as DLQ** — cheap, high-volume, durable; reuses existing Big Objects skill.
4. **OWD Private + sharing for tenant isolation** (not role hierarchy alone) — least-privilege by default; isolation is provable with a negative test.
5. **CDC for billing propagation** (not synchronous trigger chaining) — decouples billing from work-order transaction, avoids long transactions.
6. **Flow for SLA/notification orchestration** (not Apex) — declarative, admin-maintainable, justified placement.
7. **Permission sets over profiles** — deterministic deploys, CI-friendly.

---