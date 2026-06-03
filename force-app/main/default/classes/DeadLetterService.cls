public with sharing class DeadLetterService {
    public static void capture(List<service_request_event__e> events, String reason) {
        List<Failed_Event__b> rows = new List<Failed_Event__b>();
        for (service_request_event__e e : events) {
            rows.add(new Failed_Event__b(
                Event_Uuid__c         = String.isBlank(e.Event_Uuid__c)
                                          ? ServiceRequestEventPublisher.generateUuid()
                                          : e.Event_Uuid__c,
                Failed_At__c          = System.now(),
                Request_External_Id__c= e.External_Id__c,
                Payload__c            = JSON.serialize(e).left(131000),
                Failure_Reason__c     = reason == null ? 'Unknown' : reason.left(1000),
                Attempts__c           = e.Attempt__c == null ? 1 : e.Attempt__c,
                Resolved__c           = 'false'
            ));
        }
        if (!rows.isEmpty()) {
            Database.insertImmediate(rows); // Big Object DML
        }
        IntegrationLogger.log(IntegrationLogger.Direction.Internal,
            'DeadLetterCapture', null, null,
            IntegrationLogger.Outcome.Failure, null, reason);
        IntegrationLogger.flush();
    }
}
