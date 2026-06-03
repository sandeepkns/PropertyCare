public with sharing class PropertyCareSettings {
    private static PropertyCare_Setting__mdt cached;
    private static PropertyCare_Setting__mdt setting() {
        if (cached == null) {
            cached = PropertyCare_Setting__mdt.getInstance('Default');
        }
        return cached;
    }
    public static Integer maxRetryAttempts() {
        Decimal v = setting() != null ? setting().Max_Retry_Attempts__c : null;
        return v != null ? v.intValue() : 5;
    }
    public static Integer dlqAlertThreshold() {
        Decimal v = setting() != null ? setting().DLQ_Alert_Threshold__c : null;
        return v != null ? v.intValue() : 10;
    }
}