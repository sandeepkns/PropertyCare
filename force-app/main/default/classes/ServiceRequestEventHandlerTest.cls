@isTest
private class ServiceRequestEventHandlerTest {
    @isTest static void idempotentNoDuplicateWorkOrders() {
        Tenant__c t = TestDataFactory.tenant('evt1');
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id, 'EVT-IDEM', 'Urgent');
        // first work order already created by the insert trigger above
        Integer before = [SELECT COUNT() FROM Work_Order__c WHERE Service_Request__c=:sr.Id];

        // Re-deliver an event for the same request
        Test.startTest();
        EventBus.publish(new List<service_request_event__e>{
            TestDataFactory.event(sr.Id, t.Id, 'Urgent') });
        Test.stopTest();

        Integer after = [SELECT COUNT() FROM Work_Order__c WHERE Service_Request__c=:sr.Id];
        System.assertEquals(before, after, 'Duplicate event must not create a 2nd work order');
    }

    @isTest static void slaComputedFromPriority() {
        Tenant__c t = TestDataFactory.tenant('evt2');
        Test.startTest();
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id, 'EVT-SLA', 'Urgent');
        Test.stopTest();
        Work_Order__c wo = [SELECT SLA_Due__c FROM Work_Order__c WHERE Service_Request__c=:sr.Id];
        System.assert(wo.SLA_Due__c <= System.now().addHours(5), 'Urgent SLA should be ~4h');
    }
}