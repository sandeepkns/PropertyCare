public with sharing class DlqReplayBatch
        implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Iterable<SObject> start(Database.BatchableContext bc) {
        // Updated to pass a single row limit parameter (5000) matching our new selector signature
        return (Iterable<SObject>) FailedEventSelector.pendingForReplay(5000);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Service_Request_Event__e> replays = new List<Service_Request_Event__e>();
        List<Failed_Event__b> resolved = new List<Failed_Event__b>();
        
        // Cache the maximum allowed retry attempts to use for in-memory filtering
        Integer maxAttempts = PropertyCareSettings.maxRetryAttempts();

        for (SObject s : scope) {
            Failed_Event__b fe = (Failed_Event__b) s;
            
            // CRITICAL BIG OBJECT WORKAROUND: In-memory filtering
            // Skip records that are already resolved or have exceeded the maximum retry ceiling
            if (fe.Resolved__c == 'true' || (fe.Attempts__c != null && fe.Attempts__c >= maxAttempts)) {
                continue;
            }

            try {
                // Deserializing directly into the correct Service_Request_Event__e data type
                Service_Request_Event__e e =
                    (Service_Request_Event__e) JSON.deserialize(fe.Payload__c, Service_Request_Event__e.class);
                
                // Increment our singular field token (Attempt__c) on the event payload
                e.Attempt__c = (fe.Attempts__c == null ? 1 : fe.Attempts__c.intValue()) + 1;
                replays.add(e);
                
                // Mark the specific Big Object record row as resolved
                fe.Resolved__c = 'true';
                resolved.add(fe);
            } catch (Exception ex) {
                // If parsing fails, increment the tracking counter on the Big Object and save the reason
                fe.Attempts__c = (fe.Attempts__c == null ? 1 : fe.Attempts__c) + 1;
                fe.Failure_Reason__c = ('Replay parse error: ' + ex.getMessage()).left(1000);
                resolved.add(fe); 
            }
        }
        
        // Publish valid event records back to the EventBus stream
        if (!replays.isEmpty()) {
            EventBus.publish(replays);
        }
        
        // Upsert by primary key index on Big Object (insertImmediate handles updates for matching keys)
        if (!resolved.isEmpty()) {
            Database.insertImmediate(resolved); 
        }
    }

    public void finish(Database.BatchableContext bc) {
        Integer depth = FailedEventSelector.unresolvedCount();
        if (depth >= PropertyCareSettings.dlqAlertThreshold()) {
            AlertService.dlqThresholdBreached(depth);
        }
    }
}