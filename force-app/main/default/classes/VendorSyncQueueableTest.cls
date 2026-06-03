@isTest
private class VendorSyncQueueableTest {
    @isTest static void success_marksSyncedAndLogs() {
        Tenant__c t = TestDataFactory.tenant('vq1');
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id, 'VQ-1', 'Medium');
        Work_Order__c wo = [SELECT Id FROM Work_Order__c WHERE Service_Request__c=:sr.Id LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new VendorHttpMock(200, '{"ok":true}'));
        Test.startTest();
        System.enqueueJob(new VendorSyncQueueable(new Set<Id>{ wo.Id }));
        Test.stopTest();

        Work_Order__c after = [SELECT Sync_Status__c FROM Work_Order__c WHERE Id=:wo.Id];
        System.assertEquals('Synced', after.Sync_Status__c);
        Integer logs = [SELECT COUNT() FROM Integration_Log__c
                        WHERE Operation__c='VendorSync' AND Outcome__c='Success'];
        System.assert(logs >= 1, 'Success log expected');
    }

    @isTest static void terminal4xx_marksFailed() {
        Tenant__c t = TestDataFactory.tenant('vq2');
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id, 'VQ-2', 'Low');
        Work_Order__c wo = [SELECT Id FROM Work_Order__c WHERE Service_Request__c=:sr.Id LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new VendorHttpMock(400, '{"error":"bad"}'));
        Test.startTest();
        System.enqueueJob(new VendorSyncQueueable(new Set<Id>{ wo.Id }));
        Test.stopTest();

        Work_Order__c after = [SELECT Sync_Status__c FROM Work_Order__c WHERE Id=:wo.Id];
        System.assertEquals('Failed', after.Sync_Status__c, '4xx is terminal');
    }

    @isTest static void retryable5xx_logsRetry() {
        Tenant__c t = TestDataFactory.tenant('vq3');
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id, 'VQ-3', 'High');
        Work_Order__c wo = [SELECT Id FROM Work_Order__c WHERE Service_Request__c=:sr.Id LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new VendorHttpMock(503, 'unavailable'));
        Test.startTest();
        System.enqueueJob(new VendorSyncQueueable(new Set<Id>{ wo.Id }));
        Test.stopTest(); // re-enqueue suppressed under Test.isRunningTest()

        Integer retryLogs = [SELECT COUNT() FROM Integration_Log__c
                             WHERE Operation__c='VendorSync' AND Outcome__c='Retry'];
        System.assert(retryLogs >= 1, 'Retry log expected for 5xx');
    }
}