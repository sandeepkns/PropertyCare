public with sharing class RequestStatusAction {
    public class Request {
        @InvocableVariable(required=true) public Id tenantId;
        @InvocableVariable(required=true) public String requestIdentifier; // Name or External Id
    }
    public class Result {
        @InvocableVariable public String status;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Request Status' description='Returns status of the tenant\'s own request')
    public static List<Result> status(List<Request> requests) {
        List<Result> out = new List<Result>();
        for (Request r : requests) {
            Result res = new Result();
            // Tenant-scoped query — isolation boundary; never returns another tenant's data
            List<Service_Request__c> recs =
                ServiceRequestSelector.byIdForTenant(r.requestIdentifier, r.tenantId);
            if (recs.isEmpty()) {
                res.status = null;
                res.message = 'No request found on your account.'; // no fabrication
            } else {
                res.status = recs[0].Status__c;
                res.message = 'Request ' + recs[0].Name + ' is ' + recs[0].Status__c + '.';
            }
            out.add(res);
        }
        return out;
    }
}