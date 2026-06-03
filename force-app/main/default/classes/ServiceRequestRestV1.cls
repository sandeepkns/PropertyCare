@RestResource(urlMapping='/api/v1/service-requests/*')
global with sharing class ServiceRequestRestV1 {

    global class CreateRequest {
        public String externalId;
        public String tenantPortalId;
        public String category;
        public String priority;
        public String description;
        public Datetime requestedSlot;
    }

    @HttpPost
    global static void createRequest() {
        RestResponse resp = RestContext.response;
        Long start = System.currentTimeMillis();
        try {
            CreateRequest body = (CreateRequest) JSON.deserialize(
                RestContext.request.requestBody.toString(), CreateRequest.class);

            // Validation
            if (String.isBlank(body.externalId) || String.isBlank(body.tenantPortalId)
                || String.isBlank(body.category) || String.isBlank(body.priority)) {
                respond(resp, 400, '{"error":"VALIDATION_ERROR"}'); return;
            }
            // Idempotency
            if (!ServiceRequestSelector.byExternalId(body.externalId).isEmpty()) {
                respond(resp, 409, '{"error":"DUPLICATE_EXTERNAL_ID"}'); return;
            }
            // Resolve tenant
            List<Tenant__c> tenants = [
                SELECT Id FROM Tenant__c WHERE Portal_User_Id__c = :body.tenantPortalId
                WITH SECURITY_ENFORCED LIMIT 1];
            if (tenants.isEmpty()) { respond(resp, 403, '{"error":"FORBIDDEN_TENANT"}'); return; }

            Service_Request__c sr = new Service_Request__c(
                External_Id__c=body.externalId, Tenant__c=tenants[0].Id,
                Category__c=body.category, Priority__c=body.priority,
                Description__c=body.description, Requested_Slot__c=body.requestedSlot,
                Source__c='Portal', Status__c='New');
            insert sr;
            Service_Request__c created = ServiceRequestSelector.byIds(new Set<Id>{sr.Id})[0];

            IntegrationLogger.logNow(IntegrationLogger.Direction.Inbound,
                'CreateServiceRequest', sr.Id, 201, IntegrationLogger.Outcome.Success,
                (Integer)(System.currentTimeMillis()-start), null);

            respond(resp, 201, JSON.serialize(new Map<String,Object>{
                'salesforceId'=>sr.Id, 'requestNumber'=>created.Name,
                'status'=>created.Status__c, 'externalId'=>body.externalId}));
        } catch (Exception ex) {
            IntegrationLogger.logNow(IntegrationLogger.Direction.Inbound,
                'CreateServiceRequest', null, 500, IntegrationLogger.Outcome.Failure,
                null, ex.getMessage());
            respond(resp, 500, '{"error":"INTERNAL_ERROR"}');
        }
    }

    @HttpGet
    global static void getStatus() {
        RestResponse resp = RestContext.response;
        String ext = RestContext.request.requestURI.substringAfterLast('/');
        List<Service_Request__c> recs = ServiceRequestSelector.byExternalId(ext);
        if (recs.isEmpty()) { respond(resp, 404, '{"error":"NOT_FOUND"}'); return; }
        respond(resp, 200, JSON.serialize(new Map<String,Object>{
            'externalId'=>ext, 'status'=>recs[0].Status__c, 'requestNumber'=>recs[0].Name}));
    }

    private static void respond(RestResponse r, Integer code, String body) {
        r.statusCode = code;
        r.addHeader('Content-Type','application/json');
        r.responseBody = Blob.valueOf(body);
    }
}