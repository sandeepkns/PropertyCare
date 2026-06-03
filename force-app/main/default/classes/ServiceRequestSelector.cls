public with sharing class ServiceRequestSelector {
    public static List<Service_Request__c> byIds(Set<Id> ids) {
        return [
            SELECT Id, Name, Tenant__c, External_Id__c, Category__c,
                   Priority__c, Status__c, Source__c, Requested_Slot__c,
                   Description__c, Converted_Work_Order__c
            FROM Service_Request__c
            WHERE Id IN :ids
            WITH SECURITY_ENFORCED
        ];
    }

    public static List<Service_Request__c> byExternalId(String externalId) {
        return [
            SELECT Id, Name, External_Id__c, Status__c, Tenant__c
            FROM Service_Request__c
            WHERE External_Id__c = :externalId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    // Tenant-scoped lookup — the isolation boundary for agent actions
    public static List<Service_Request__c> byIdForTenant(String reqIdentifier, Id tenantId) {
        return [
            SELECT Id, Name, Status__c, Priority__c, Converted_Work_Order__c, Tenant__c
            FROM Service_Request__c
            WHERE Tenant__c = :tenantId
              AND (Name = :reqIdentifier OR External_Id__c = :reqIdentifier)
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }
}