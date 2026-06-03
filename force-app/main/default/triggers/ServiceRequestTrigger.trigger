trigger ServiceRequestTrigger on Service_Request__c (before insert, after insert) {
    new ServiceRequestTriggerHandler().run();
}