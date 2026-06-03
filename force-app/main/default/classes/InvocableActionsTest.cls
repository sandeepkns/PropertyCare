@isTest
private class InvocableActionsTest {
    @isTest static void bookCreatesRequest() {
        Tenant__c t = TestDataFactory.tenant('inv1');
        BookServiceSlotAction.Request r = new BookServiceSlotAction.Request();
        r.tenantId=t.Id; r.category='Plumbing'; r.priority='High';
        r.description='Leak'; r.requestedSlot=System.now().addDays(1);

        Test.startTest();
        List<BookServiceSlotAction.Result> res =
            BookServiceSlotAction.book(new List<BookServiceSlotAction.Request>{ r });
        Test.stopTest();

        System.assert(res[0].message.contains('created'));
        System.assertEquals(1,[SELECT COUNT() FROM Service_Request__c WHERE Tenant__c=:t.Id]);
    }

    @isTest static void statusNotFoundDoesNotFabricate() {
        Tenant__c t = TestDataFactory.tenant('inv2');
        RequestStatusAction.Request r = new RequestStatusAction.Request();
        r.tenantId=t.Id; r.requestIdentifier='SR-DOES-NOT-EXIST';
        List<RequestStatusAction.Result> res =
            RequestStatusAction.status(new List<RequestStatusAction.Request>{ r });
        System.assertEquals(null, res[0].status);
    }

    @isTest static void soaTotalsCorrectly() {
        Tenant__c t = TestDataFactory.tenant('inv3');
        Service_Request__c sr = TestDataFactory.serviceRequest(t.Id,'SOA-1','Low');
        Work_Order__c wo = [SELECT Id FROM Work_Order__c WHERE Service_Request__c=:sr.Id LIMIT 1];
        Billing_Statement__c b = TestDataFactory.billing(wo.Id, t.Id);
        b.Billing_Status__c='Issued'; b.Amount__c=300; update b;

        GenerateSOAAction.Request r = new GenerateSOAAction.Request();
        r.tenantId=t.Id; r.period=null;
        List<GenerateSOAAction.Result> res =
            GenerateSOAAction.generate(new List<GenerateSOAAction.Request>{ r });
        System.assertEquals(300, res[0].totalDue);
        System.assertEquals(1, res[0].lineCount);
    }
}