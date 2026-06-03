@isTest
private class SecurityIsolationTest {

    // 1) Action-layer isolation: tenant A cannot read tenant B's request
    @isTest static void requestStatus_doesNotCrossTenant() {
        Tenant__c a = TestDataFactory.tenant('iso-a');
        Tenant__c b = TestDataFactory.tenant('iso-b');
        Service_Request__c bReq = TestDataFactory.serviceRequest(b.Id, 'ISO-B-1', 'High');

        RequestStatusAction.Request r = new RequestStatusAction.Request();
        r.tenantId = a.Id;                 // tenant A's context
        r.requestIdentifier = bReq.Name;   // asking for tenant B's request

        Test.startTest();
        List<RequestStatusAction.Result> res =
            RequestStatusAction.status(new List<RequestStatusAction.Request>{ r });
        Test.stopTest();

        System.assertEquals(null, res[0].status, 'Must not reveal another tenant\'s status');
        System.assert(res[0].message.contains('No request'),
            'Cross-tenant lookup must return not-found, never the record');
    }

    // 2) OWD-private isolation under a restricted running user
    @isTest static void owdPrivate_blocksOtherOwnersRecords() {
        Tenant__c owner = TestDataFactory.tenant('iso-owner');
        Service_Request__c sr = TestDataFactory.serviceRequest(owner.Id, 'ISO-OWD', 'Low');

        User restricted = makeMinimalUser();
        System.runAs(restricted) {
            List<Service_Request__c> visible =
                [SELECT Id FROM Service_Request__c WHERE Id = :sr.Id];
            System.assertEquals(0, visible.size(),
                'Under OWD Private a non-owner with no sharing sees nothing');
        }
    }

    private static User makeMinimalUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName='Min', LastName='User',
            Email='minuser@pc.test', Username='minuser-'+
                String.valueOf(Datetime.now().getTime())+'@pc.test',
            Alias='min', TimeZoneSidKey='UTC', LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', ProfileId=p.Id);
        insert u;
        return u;
    }
}