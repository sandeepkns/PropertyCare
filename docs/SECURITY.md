# PropertyCare Security Architecture Specifications

## 1. Threat Model & External Ingress Surface Area
The external Node.js Portal communicates with Salesforce via two primary vectors:
* **Inbound REST API (`/services/apexrest/api/v1/service-requests/*`)**: Protected via high-assurance **OAuth 2.0 JWT Bearer Flow**. No long-lived username/password secrets are stored in the external subsystem.
* **Outbound Status Webhook (`/sf-webhook/work-order`)**: Protected via dynamic symmetric **HMAC SHA256 Cryptographic Signatures** computed over raw request bodies using a shared secret.

## 2. Organization-Wide Defaults (OWD) & Data Isolation
* **`Tenant__c` OWD**: Set to **Private**.
* **`Service_Request__c` OWD**: Set to **Controlled by Parent**.
* **Sharing Enforcement**: All Apex controllers, selectors, and handlers explicitly utilize the `with sharing` keyword context. Cross-tenant data leaks are programmatically impossible; query filters always resolve matching records strictly against the authenticated user's correlated `Portal_User_Id__c` mapping.

## 3. Defensive Programming & Schema Safeguards
To guarantee complete field-level security (FLS) immunity against malicious injection mutations, all custom Apex modification routes run raw data frames through the system engine's schema parsing layers:
* `Security.stripInaccessible(AccessType.CREATABLE, ...)` is strictly enforced prior to executing any Inbound DML.
* Selective query vectors utilize `WITH SECURITY_ENFORCED` clauses to guarantee field visibility boundary isolation compliance.