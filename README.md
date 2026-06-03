# PropertyCare — Connected Agentforce Maintenance Ecosystem

PropertyCare is an enterprise-grade, fully decoupled, and asynchronous application architecture built to bridge internal Salesforce core CRM operations with an external, customer-facing Tenant Repair Portal. 

By avoiding synchronous transaction coupling, the system ensures high-throughput reliability, resilient self-healing network rails, and robust defense-in-depth security boundaries.

---

## 🏗️ Architectural Topology Matrix

The ecosystem operates across three tightly integrated, decoupled network layers:

### 1. High-Assurance Inbound Gateway (JWT Secured)
* **Ingress Vector**: The external Node.js/Express subsystem authenticates headless API handshakes via an **OAuth 2.0 JWT Bearer Flow** assertion token.
* **Custom Custom Endpoint Engine**: Routes payloads directly into a versioned REST Resource class (`/api/v1/service-requests/*`).
* **Schema Protection**: Programmatically shields the database layer from data mutations by running input fields through `Security.stripInaccessible` schema scrubbing prior to committing DML.

### 2. Event-Driven Outbound Pipeline (Symmetric Signature Verification)
* **Decoupled Detection**: Data status changes are captured asynchronously via Salesforce **Change Data Capture (CDC)** message buses, removing sync overhead from standard user layouts.
* **Bulkified Transport**: A dedicated trigger consumer intercepts the CDC events and hands processing off to a bulkified, queueable handler engine (`VendorSyncQueueable`).
* **Secure Delivery**: Routes traffic out of the platform via **Named Credentials**. To guarantee data integrity in transit, an inline cryptographically computed symmetric **HMAC SHA256 signature** is attached to the request headers (`X-PropertyCare-Signature`) for the Node server to validate.

### 3. Asynchronous Resilient Self-Healing Loop (Big Object Store)
* **Durable Storage Shield**: If an outbound callout encounters transport-layer or remote server failure, it avoids hitting standard relational database storage limits or blocking production threads by shifting payload payloads directly into a **Custom Big Object Store (`Failed_Event__b`)**.
* **Primary Key Safety**: Uses deterministic composite index parameters (`Event_Uuid__c` + `Failed_At__c`) to allow high-volume write speeds and duplicate tracking optimization.
* **Background Recovery**: An hourly batch engine evaluates outstanding rows *in-memory* to bypass Big Object table scan limitations and attempts delivery up to a configured threshold (`5` attempts). If it hits the ceiling, it hands processing off to a custom dashboard interface for manual administrator triage.

---

## 🛠️ Integrated Core Engineering Stack

```text
PropertyCare/
├── force-app/main/default/         <-- Salesforce Metadata Architecture
│   ├── classes/                    <-- Selective Selectors, Queueables, & Rest Resouces
│   ├── lwc/integrationMonitor/     <-- Reactive Dashboard Control Interface
│   └── objects/                    <-- Secure Private Sharing Model Custom Schema
└── portal/                         <-- External Subsystem Architecture
    ├── src/auth/sfJwt.js           <-- Headless JWT Generation Engine
    ├── src/routes/webhook.js       <-- HMAC Signature Security Validator
    └── src/server.js               <-- Express Application Entry Framework