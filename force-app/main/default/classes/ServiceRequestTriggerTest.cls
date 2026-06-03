@isTest
private class ServiceRequestTriggerTest {
    @isTest static void publishesEventAndCreatesWorkOrder() {
        Tenant__c t = TestDataFactory.tenant('trig1');
        Test.startTest();
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id, 'SR-EXT-1', 'High');
        // Platform events publish after commit; Test.stopTest delivers them
        Test.stopTest();

        // Event handler should have created a work order and marked converted
        List<Work_Order__c> wos = [SELECT Id, Status__c, Tenant__c FROM Work_Order__c
                                   WHERE Service_Request__c = :sr.Id];
        System.assertEquals(1, wos.size(), 'One work order expected');
        System.assertEquals('Open', wos[0].Status__c);

        Service_Request__c reloaded = [SELECT Status__c, Converted_Work_Order__c
                                       FROM Service_Request__c WHERE Id = :sr.Id];
        System.assertEquals('Converted', reloaded.Status__c);
        System.assertEquals(wos[0].Id, reloaded.Converted_Work_Order__c);
    }

    @isTest static void defaultsApplied() {
        Tenant__c t = TestDataFactory.tenant('trig2');
        Service_Request__c sr = new Service_Request__c(
            Tenant__c=t.Id, External_Id__c='SR-EXT-2',
            Category__c='HVAC', Priority__c='Low');
        insert sr;
        Service_Request__c r = [SELECT Status__c, Source__c FROM Service_Request__c WHERE Id=:sr.Id];
        System.assertEquals('New', r.Status__c);
        System.assertEquals('Agent', r.Source__c);
    }
}