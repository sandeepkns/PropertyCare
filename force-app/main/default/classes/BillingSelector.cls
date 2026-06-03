public with sharing class BillingSelector {
    
    public static List<Billing_Statement__c> byWorkOrderIds(Set<Id> woIds) {
        return [
            SELECT Id, Tenant__c, Work_Order__c, Amount__c,
                   Billing_Status__c, Issued_Date__c, Statement_Period__c
            FROM Billing_Statement__c
            WHERE Work_Order__c IN :woIds
            WITH SECURITY_ENFORCED
        ];
    }

    public static List<Billing_Statement__c> byTenant(Id tenantId, String period) {
        // If no specific period is requested, return all statement history records for the tenant
        if (String.isBlank(period)) {
            return [
                SELECT Id, Name, Amount__c, Billing_Status__c, Issued_Date__c,
                       Statement_Period__c, Work_Order__r.Name
                FROM Billing_Statement__c
                WHERE Tenant__c = :tenantId
                WITH SECURITY_ENFORCED
                ORDER BY Issued_Date__c DESC
            ];
        }
        
        // If a valid period is supplied, strictly filter down to that specific period row array
        return [
            SELECT Id, Name, Amount__c, Billing_Status__c, Issued_Date__c,
                   Statement_Period__c, Work_Order__r.Name
            FROM Billing_Statement__c
            WHERE Tenant__c = :tenantId
              AND Statement_Period__c = :period
            WITH SECURITY_ENFORCED
            ORDER BY Issued_Date__c DESC
        ];
    }
}