public with sharing class SecurityUtil {
    // Strip fields the running user can't read, return safe records
    public static List<SObject> readable(List<SObject> records) {
        if (records == null || records.isEmpty()) return records;
        SObjectAccessDecision d =
            Security.stripInaccessible(AccessType.READABLE, records);
        return d.getRecords();
    }

    // Strip fields the running user can't create/update before DML
    public static List<SObject> creatable(List<SObject> records) {
        if (records == null || records.isEmpty()) return records;
        SObjectAccessDecision d =
            Security.stripInaccessible(AccessType.CREATABLE, records);
        return d.getRecords();
    }

    public static Boolean canCreate(SObjectType t) {
        return t.getDescribe().isCreateable();
    }
    public static Boolean canRead(SObjectType t) {
        return t.getDescribe().isAccessible();
    }
}