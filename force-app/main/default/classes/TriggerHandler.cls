public virtual class TriggerHandler {
    private static Set<String> bypassed = new Set<String>();

    public void run() {
        if (bypassed.contains(getName())) return;
        if (Trigger.isBefore && Trigger.isInsert) beforeInsert();
        else if (Trigger.isAfter && Trigger.isInsert) afterInsert();
        else if (Trigger.isBefore && Trigger.isUpdate) beforeUpdate();
        else if (Trigger.isAfter && Trigger.isUpdate) afterUpdate();
    }

    protected virtual void beforeInsert() {}
    protected virtual void afterInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void afterUpdate() {}

    private String getName() { return String.valueOf(this).split(':')[0]; }

    public static void bypass(String handlerName) { bypassed.add(handlerName); }
    public static void clearBypass(String handlerName) { bypassed.remove(handlerName); }
}