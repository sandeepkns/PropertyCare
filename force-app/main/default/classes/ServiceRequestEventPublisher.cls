public with sharing class ServiceRequestEventPublisher {
    public static void publish(List<Service_Request__c> requests) {
        List<Service_Request_Event__e> events = new List<Service_Request_Event__e>();
        for (Service_Request__c sr : requests) {
            events.add(new Service_Request_Event__e(
                Request_Id__c  = sr.Id,
                External_Id__c = sr.External_Id__c,
                Tenant_Id__c   = sr.Tenant__c,
                Priority__c    = sr.Priority__c,
                Event_Uuid__c  = generateUuid(),
                Attempt__c     = 1
            ));
        }
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult r : results) {
            if (!r.isSuccess()) {
                IntegrationLogger.log(IntegrationLogger.Direction.Internal,
                    'PublishServiceRequestEvent', null, null,
                    IntegrationLogger.Outcome.Failure, null,
                    String.valueOf(r.getErrors()));
            }
        }
        IntegrationLogger.flush();
    }

    public static String generateUuid() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        return h.substring(0,8)+'-'+h.substring(8,12)+'-'+h.substring(12,16)
             +'-'+h.substring(16,20)+'-'+h.substring(20,32);
    }
}