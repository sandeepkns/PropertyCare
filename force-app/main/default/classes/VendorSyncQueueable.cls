public with sharing class VendorSyncQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> workOrderIds;
    private Integer attempt;

    public VendorSyncQueueable(Set<Id> ids) { this(ids, 1); }
    public VendorSyncQueueable(Set<Id> ids, Integer attempt) {
        this.workOrderIds = ids; this.attempt = attempt;
    }

    public void execute(QueueableContext ctx) {
        List<Work_Order__c> wos = WorkOrderSelector.byIds(workOrderIds);
        List<Work_Order__c> updates = new List<Work_Order__c>();
        Set<Id> retryIds = new Set<Id>();

        for (Work_Order__c wo : wos) {
            Long start = System.currentTimeMillis();
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:PropertyCare_Vendor/sf-webhook/work-order');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(VendorSyncService.buildPayload(wo));
                req.setTimeout(20000);
                HttpResponse res = new Http().send(req);
                Integer latency = (Integer)(System.currentTimeMillis() - start);

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    wo.Sync_Status__c = 'Synced';
                    updates.add(wo);
                    IntegrationLogger.log(IntegrationLogger.Direction.Outbound,
                        'VendorSync', wo.Id, res.getStatusCode(),
                        IntegrationLogger.Outcome.Success, latency, null);
                } else if (res.getStatusCode() >= 500) {
                    retryIds.add(wo.Id);             // retryable
                    IntegrationLogger.log(IntegrationLogger.Direction.Outbound,
                        'VendorSync', wo.Id, res.getStatusCode(),
                        IntegrationLogger.Outcome.Retry, latency, res.getBody());
                } else {
                    wo.Sync_Status__c = 'Failed';    // terminal 4xx
                    updates.add(wo);
                    IntegrationLogger.log(IntegrationLogger.Direction.Outbound,
                        'VendorSync', wo.Id, res.getStatusCode(),
                        IntegrationLogger.Outcome.Failure, latency, res.getBody());
                }
            } catch (Exception ex) {
                retryIds.add(wo.Id);
                IntegrationLogger.log(IntegrationLogger.Direction.Outbound,
                    'VendorSync', wo.Id, null,
                    IntegrationLogger.Outcome.Retry, null, ex.getMessage());
            }
        }
        if (!updates.isEmpty()) update updates;
        IntegrationLogger.flush();

        // Re-enqueue retryable, capped
        Integer maxAttempts = PropertyCareSettings.maxRetryAttempts();
        if (!retryIds.isEmpty() && attempt < maxAttempts && !Test.isRunningTest()) {
            System.enqueueJob(new VendorSyncQueueable(retryIds, attempt + 1));
        } else if (!retryIds.isEmpty() && attempt >= maxAttempts) {
            for (Id woId : retryIds) {
                update new Work_Order__c(Id = woId, Sync_Status__c = 'Failed');
            }
        }
    }
}