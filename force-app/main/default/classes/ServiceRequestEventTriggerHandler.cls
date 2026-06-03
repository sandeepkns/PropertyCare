public with sharing class ServiceRequestEventTriggerHandler {
    public void handle(List<service_request_event__e> events) {
        // Idempotency: skip requests that already have a work order
        Set<Id> requestIds = new Set<Id>();
        for (service_request_event__e e : events) {
            if (e.Request_Id__c != null) requestIds.add(e.Request_Id__c);
        }
        Set<Id> alreadyConverted = new Set<Id>();
        for (Work_Order__c wo : [
            SELECT Service_Request__c FROM Work_Order__c
            WHERE Service_Request__c IN :requestIds
        ]) {
            alreadyConverted.add(wo.Service_Request__c);
        }

        List<service_request_event__e> toProcess = new List<service_request_event__e>();
        for (service_request_event__e e : events) {
            if (!alreadyConverted.contains(e.Request_Id__c)) toProcess.add(e);
        }
        if (toProcess.isEmpty()) return;

        try {
            List<Work_Order__c> wos = WorkOrderService.buildFromEvents(toProcess);
            insert wos;
            // back-reference + mark converted
            Map<Id,Id> reqToWo = new Map<Id,Id>();
            for (Work_Order__c wo : wos) reqToWo.put(wo.Service_Request__c, wo.Id);
            List<Service_Request__c> updates = new List<Service_Request__c>();
            for (Id reqId : reqToWo.keySet()) {
                updates.add(new Service_Request__c(
                    Id = reqId, Status__c = 'Converted', Converted_Work_Order__c = reqToWo.get(reqId)));
            }
            update updates;
            WorkOrderService.enqueueVendorSync(new Set<Id>(reqToWo.values()));
        } catch (Exception ex) {
            // Dead-letter the failed events
            DeadLetterService.capture(toProcess, ex.getMessage());
        }
        IntegrationLogger.flush();
    }
}