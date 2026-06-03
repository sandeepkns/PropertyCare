public with sharing class ServiceRequestDomain {
    // Defaulting + invariants before insert
    public static void applyDefaults(List<Service_Request__c> records) {
        for (Service_Request__c sr : records) {
            if (String.isBlank(sr.Status__c)) sr.Status__c = 'New';
            if (String.isBlank(sr.Source__c)) sr.Source__c = 'Agent';
        }
    }
}