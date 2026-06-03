public with sharing class DlqDepthAlertScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        // Query the unresolved dead letter queue entry size count over selectors
        Integer unresolvedCount = FailedEventSelector.unresolvedCount();
        Integer dangerThreshold = PropertyCareSettings.dlqAlertThreshold();

        if (unresolvedCount >= dangerThreshold) {
            dispatchSystemAdministratorBreachEmail(unresolvedCount);
        }
    }

    private static void dispatchSystemAdministratorBreachEmail(Integer currentDepth) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Target structural infrastructure monitoring mail queues
        String[] toAddresses = new String[] { 'propertycare-ops@example.com' }; 
        mail.setToAddresses(toAddresses);
        
        mail.setSubject('[CRITICAL ALERT] PropertyCare DLQ Threshold Breach Warning');
        mail.setPlainTextBody(
            'System Warning: The custom Dead Letter Queue (Failed_Event__b) has crossed its operational capacity thresholds.\n\n' +
            'Current Unresolved Rows Count: ' + currentDepth + '\n' +
            'Configured Threshold Target: ' + PropertyCareSettings.dlqAlertThreshold() + '\n\n' +
            'Action Required: Open the PropertyCare Integration Monitoring Console immediately to manually audit logs and replay stuck payloads.'
        );
        
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }
}