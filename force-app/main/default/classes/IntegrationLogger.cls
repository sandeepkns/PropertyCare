public with sharing class IntegrationLogger {
    public enum Outcome { Success, Failure, Retry }
    public enum Direction { Inbound, Outbound, Internal }

    private static List<Integration_Log__c> buffer = new List<Integration_Log__c>();

    public static void log(Direction dir, String operation, String relatedId,
                           Integer statusCode, Outcome outcome,
                           Integer latencyMs, String message) {
        buffer.add(new Integration_Log__c(
            Direction__c        = dir.name(),
            Operation__c        = operation,
            Related_Record_Id__c= relatedId,
            Status_Code__c      = statusCode,
            Outcome__c          = outcome.name(),
            Latency_Ms__c       = latencyMs,
            Message__c          = message == null ? null : message.left(32000),
            Logged_At__c        = System.now()
        ));
    }

    // Flush buffered logs (call at end of a unit of work)
    public static void flush() {
        if (buffer.isEmpty()) return;
        try {
            insert buffer;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Log flush failed: ' + e.getMessage());
        } finally {
            buffer.clear();
        }
    }

    // Convenience for single immediate insert (e.g. from REST)
    public static void logNow(Direction dir, String op, String relatedId,
                              Integer statusCode, Outcome outcome,
                              Integer latencyMs, String message) {
        log(dir, op, relatedId, statusCode, outcome, latencyMs, message);
        flush();
    }
}