@isTest
private class ServiceRequestRestV1Test {

    private static RestRequest buildReq(String body, String method, String uri) {
        RestRequest req = new RestRequest();
        req.requestURI = uri;
        req.httpMethod = method;
        if (body != null) req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        return req;
    }

    @isTest static void post_createsRequest_201() {
        Tenant__c t = TestDataFactory.tenant('rest1');
        String body = JSON.serialize(new Map<String,Object>{
            'externalId'=>'REST-1','tenantPortalId'=>'rest1',
            'category'=>'Electrical','priority'=>'High'});
        buildReq(body, 'POST', '/api/v1/service-requests');

        Test.startTest();
        ServiceRequestRestV1.createRequest();
        Test.stopTest();

        System.assertEquals(201, RestContext.response.statusCode);
        System.assertEquals(1,[SELECT COUNT() FROM Service_Request__c WHERE External_Id__c='REST-1']);
    }

    @isTest static void post_validationError_400() {
        buildReq('{"externalId":""}', 'POST', '/api/v1/service-requests');
        ServiceRequestRestV1.createRequest();
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest static void post_duplicate_409() {
        Tenant__c t = TestDataFactory.tenant('rest2');
        TestDataFactory.serviceRequest(t.Id, 'DUP-1', 'Low');
        String body = JSON.serialize(new Map<String,Object>{
            'externalId'=>'DUP-1','tenantPortalId'=>'rest2',
            'category'=>'HVAC','priority'=>'Low'});
        buildReq(body, 'POST', '/api/v1/service-requests');
        ServiceRequestRestV1.createRequest();
        System.assertEquals(409, RestContext.response.statusCode);
    }

    @isTest static void post_unknownTenant_403() {
        String body = JSON.serialize(new Map<String,Object>{
            'externalId'=>'REST-NO-TENANT','tenantPortalId'=>'nobody',
            'category'=>'General','priority'=>'Medium'});
        buildReq(body, 'POST', '/api/v1/service-requests');
        ServiceRequestRestV1.createRequest();
        System.assertEquals(403, RestContext.response.statusCode);
    }

    @isTest static void get_status_200_and_404() {
        Tenant__c t = TestDataFactory.tenant('rest3');
        TestDataFactory.serviceRequest(t.Id, 'GET-1', 'High');
        buildReq(null, 'GET', '/api/v1/service-requests/GET-1');
        ServiceRequestRestV1.getStatus();
        System.assertEquals(200, RestContext.response.statusCode);

        buildReq(null, 'GET', '/api/v1/service-requests/NOPE');
        ServiceRequestRestV1.getStatus();
        System.assertEquals(404, RestContext.response.statusCode);
    }
}