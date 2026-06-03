public with sharing class AlertService {
    public static void dlqThresholdBreached(Integer depth) {
        // Email alert (Slack via Named Credential webhook is an alternative)
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ UserInfo.getUserEmail() });
        mail.setSubject('[PropertyCare] DLQ threshold breached: ' + depth + ' unresolved');
        mail.setPlainTextBody('Unresolved Failed_Event__b rows: ' + depth
            + '. Review the monitoring console.');
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
        }
        IntegrationLogger.logNow(IntegrationLogger.Direction.Internal,
            'DlqAlert', null, null, IntegrationLogger.Outcome.Failure, null,
            'DLQ depth ' + depth);
    }
}
