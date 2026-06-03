public with sharing class ServiceRequestTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        ServiceRequestDomain.applyDefaults((List<Service_Request__c>) Trigger.new);
    }
    protected override void afterInsert() {
        ServiceRequestEventPublisher.publish((List<Service_Request__c>) Trigger.new);
    }
}