public with sharing class IntegrationMonitorController {

    @AuraEnabled(cacheable=true)
    public static List<Integration_Log__c> recentLogs(String outcomeFilter) {
        // If the filter is blank, pull the recent logs regardless of the outcome status
        if (String.isBlank(outcomeFilter)) {
            return [
                SELECT Id, Name, Direction__c, Operation__c, Related_Record_Id__c,
                       Status_Code__c, Outcome__c, Latency_Ms__c, Logged_At__c, Message__c
                FROM Integration_Log__c
                WITH SECURITY_ENFORCED
                ORDER BY Logged_At__c DESC
                LIMIT 100
            ];
        }

        // If a valid filter is provided, enforce it directly in a clean equality condition
        return [
            SELECT Id, Name, Direction__c, Operation__c, Related_Record_Id__c,
                   Status_Code__c, Outcome__c, Latency_Ms__c, Logged_At__c, Message__c
            FROM Integration_Log__c
            WHERE Outcome__c = :outcomeFilter
            WITH SECURITY_ENFORCED
            ORDER BY Logged_At__c DESC
            LIMIT 100
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Integer dlqDepth() {
        return FailedEventSelector.unresolvedCount();
    }

    @AuraEnabled
    public static String replayDlq() {
        Id jobId = Database.executeBatch(new DlqReplayBatch(), 200);
        return String.valueOf(jobId);
    }
}