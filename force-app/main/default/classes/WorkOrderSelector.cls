public with sharing class WorkOrderSelector {
    public static List<Work_Order__c> byIds(Set<Id> ids) {
        return [
            SELECT Id, Name, Service_Request__c, Tenant__c, Status__c,
                   SLA_Due__c, Vendor_Ref__c, Sync_Status__c,
                   Completed_Date__c, Amount__c
            FROM Work_Order__c
            WHERE Id IN :ids
            WITH SECURITY_ENFORCED
        ];
    }

    public static List<Work_Order__c> byServiceRequestExternalId(String externalId) {
        return [
            SELECT Id, Name, Service_Request__r.External_Id__c
            FROM Work_Order__c
            WHERE Service_Request__r.External_Id__c = :externalId
            WITH SECURITY_ENFORCED
        ];
    }
}