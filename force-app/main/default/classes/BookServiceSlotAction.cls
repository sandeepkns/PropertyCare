public with sharing class BookServiceSlotAction {
    public class Request {
        @InvocableVariable(required=true) public Id tenantId;
        @InvocableVariable(required=true) public String category;
        @InvocableVariable(required=true) public String priority;
        @InvocableVariable public String description;
        @InvocableVariable public Datetime requestedSlot;
    }
    public class Result {
        @InvocableVariable public String requestNumber;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Book Service Slot' description='Creates a tenant service request')
    public static List<Result> book(List<Request> requests) {
        List<Result> results = new List<Result>();
        List<Service_Request__c> toInsert = new List<Service_Request__c>();
        for (Request r : requests) {
            toInsert.add(new Service_Request__c(
                Tenant__c=r.tenantId, Category__c=r.category, Priority__c=r.priority,
                Description__c=r.description, Requested_Slot__c=r.requestedSlot,
                Source__c='Agent', Status__c='New',
                External_Id__c='AGENT-'+ServiceRequestEventPublisher.generateUuid()));
        }
        // FLS-safe insert
        List<SObject> safe = SecurityUtil.creatable(toInsert);
        insert safe;
        for (SObject s : safe) {
            Service_Request__c sr = (Service_Request__c) s;
            Result res = new Result();
            res.requestNumber = sr.Name; // populated after insert via reload if needed
            res.message = 'Your request was created.';
            results.add(res);
        }
        return results;
    }
}
