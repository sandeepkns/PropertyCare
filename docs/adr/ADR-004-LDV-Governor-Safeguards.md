# ADR-004: Large Data Volume (LDV) Governor Safeguards

## Status
Approved

## Context
Operating at an organizational scale containing >500,000 database rows introduces performance degradation concerns if non-selective SOQL queries or synchronous transport processing blocks are executed.

## Decision Details
1. **Asynchronous Outbound Splitting**: We explicitly transitioned outbound network calls from real-time execution threads into a bulkified asynchronous `Queueable` layer (`VendorSyncQueueable`). This prevents active database transactions from hanging open while waiting for external server socket connections to complete.
2. **Batch Ingestion Splitting**: The `DataGeneratorBatch` size parameters were structured using an input loop size of 10,000 elements processed sequentially. This keeps heap tracking profiles far beneath the platform's `12MB` asynchronous runtime limits while executing DML arrays safely.
3. **Index Targeting**: The selection routing pathways enforce strict equality constraints utilizing the uniquely designated `External_Id__c` field (which automatically instantiates an index under the hood), maintaining query analysis execution cost scores far beneath `1.00`.

## Consequences
Maintains optimal database selectivity, guarantees zero UI-blocking runtime frames, and ensures complete immunity to standard platform 50k row limit exceptions.