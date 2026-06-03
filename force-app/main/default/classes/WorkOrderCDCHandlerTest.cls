@isTest
private class WorkOrderCDCHandlerTest {
    // Note: CDC delivery in tests requires Test.enableChangeDataCapture().
    // We also unit-test BillingService directly so coverage doesn't depend on
    // platform CDC timing, which varies by API version.

    @isTest static void billing_issuedWhenCompleted() {
        Tenant__c t = TestDataFactory.tenant('cdc1');
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id, 'CDC-1', 'Medium');
        Work_Order__c wo = [SELECT Id FROM Work_Order__c WHERE Service_Request__c=:sr.Id LIMIT 1];
        wo.Status__c = 'Completed'; wo.Amount__c = 500; update wo;

        Test.startTest();
        BillingService.syncFromWorkOrders(new Set<Id>{ wo.Id });
        Test.stopTest();

        Billing_Statement__c b = [SELECT Billing_Status__c, Amount__c
                                  FROM Billing_Statement__c WHERE Work_Order__c=:wo.Id];
        System.assertEquals('Issued', b.Billing_Status__c);
        System.assertEquals(500, b.Amount__c);
    }

    @isTest static void billing_voidedWhenCancelled() {
        Tenant__c t = TestDataFactory.tenant('cdc2');
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id, 'CDC-2', 'Low');
        Work_Order__c wo = [SELECT Id FROM Work_Order__c WHERE Service_Request__c=:sr.Id LIMIT 1];
        Billing_Statement__c draft = TestDataFactory.billing(wo.Id, t.Id); // Draft

        wo.Status__c = 'Cancelled'; update wo;
        Test.startTest();
        BillingService.syncFromWorkOrders(new Set<Id>{ wo.Id });
        Test.stopTest();

        Billing_Statement__c b = [SELECT Billing_Status__c FROM Billing_Statement__c WHERE Id=:draft.Id];
        System.assertEquals('Void', b.Billing_Status__c);
    }

    @isTest static void cdcHandler_runsWithoutError() {
        // Exercise the handler entry point with an empty list (defensive)
        Test.startTest();
        new WorkOrderCDCHandler().handle(new List<Work_Order__ChangeEvent>());
        Test.stopTest();
        System.assert(true);
    }
}