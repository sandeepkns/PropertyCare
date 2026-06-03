public with sharing class WorkOrderService {
    // SLA hours by priority
    private static final Map<String,Integer> SLA_HOURS = new Map<String,Integer>{
        'Urgent'=>4, 'High'=>24, 'Medium'=>72, 'Low'=>168
    };

    public static List<Work_Order__c> buildFromEvents(List<service_request_event__e> events) {
        List<Work_Order__c> wos = new List<Work_Order__c>();
        for (service_request_event__e e : events) {
            Integer hours = SLA_HOURS.containsKey(e.Priority__c)
                ? SLA_HOURS.get(e.Priority__c) : 72;
            wos.add(new Work_Order__c(
                Service_Request__c = e.Request_Id__c,
                Tenant__c          = e.Tenant_Id__c,
                Status__c          = 'Open',
                Sync_Status__c     = 'Pending',
                SLA_Due__c         = System.now().addHours(hours)
            ));
        }
        return wos;
    }

    public static void enqueueVendorSync(Set<Id> workOrderIds) {
        if (!workOrderIds.isEmpty()) {
            System.enqueueJob(new VendorSyncQueueable(workOrderIds));
        }
    }

    public static void handleOutboundStatusSynchronization(Set<Id> updatedWorkOrderIds) {
    if (updatedWorkOrderIds == null || updatedWorkOrderIds.isEmpty()) return;
    
    // Asynchronous safety block guardrail: Offload network calls cleanly via system Queueable dispatch paths
    System.enqueueJob(new VendorSyncQueueable(updatedWorkOrderIds));
}
}