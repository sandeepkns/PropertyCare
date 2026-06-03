public with sharing class VendorSyncService {
    public static String buildPayload(Work_Order__c wo) {
        return JSON.serialize(new Map<String,Object>{
            'workOrderId' => wo.Name,
            'status'      => wo.Status__c,
            'slaDue'      => wo.SLA_Due__c,
            'tenantId'    => wo.Tenant__c
        });
    }
}