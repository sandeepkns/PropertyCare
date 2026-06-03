@isTest
public class TestDataFactory {

    public static Tenant__c tenant(String portalId) {
        Tenant__c t = new Tenant__c(
            Name = 'Tenant ' + portalId,
            Email__c = portalId + '@pc.test',
            Portal_User_Id__c = portalId,
            Active__c = true
        );
        insert t;
        return t;
    }

    public static Service_Request__c serviceRequest(Id tenantId, String ext, String priority) {
        Service_Request__c sr = new Service_Request__c(
            Tenant__c = tenantId,
            External_Id__c = ext,
            Category__c = 'Plumbing',
            Priority__c = priority,
            Status__c = 'New',
            Source__c = 'Portal'
        );
        insert sr;
        return sr;
    }

    public static Work_Order__c workOrder(Id srId, Id tenantId, String status) {
        Work_Order__c wo = new Work_Order__c(
            Service_Request__c = srId,
            Tenant__c = tenantId,
            Status__c = status,
            Sync_Status__c = 'Pending',
            Amount__c = 250.00,
            SLA_Due__c = System.now().addHours(24)
        );
        insert wo;
        return wo;
    }

    public static Billing_Statement__c billing(Id woId, Id tenantId) {
        Billing_Statement__c b = new Billing_Statement__c(
            Work_Order__c = woId,
            Tenant__c = tenantId,
            Amount__c = 250.00,
            Billing_Status__c = 'Draft'
        );
        insert b;
        return b;
    }

    public static Service_Request_event__e event(Id reqId, Id tenantId, String priority) {
        return new Service_Request_event__e(
            Request_Id__c = reqId,
            External_Id__c = 'EVT-' + reqId,
            Tenant_Id__c = tenantId,
            Priority__c = priority,
            Event_Uuid__c = ServiceRequestEventPublisher.generateUuid(),
            Attempt__c = 1
        );
    }
}