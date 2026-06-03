public with sharing class WorkOrderCDCHandler {
    public void handle(List<Work_Order__ChangeEvent> events) {
        Set<Id> changedWorkOrders = new Set<Id>();
        for (Work_Order__ChangeEvent e : events) {
            EventBus.ChangeEventHeader h = e.ChangeEventHeader;
            // Act only when Status__c is among changed fields
            if (h.getChangedFields() != null &&
                new Set<String>(h.getChangedFields()).contains('Status__c')) {
                for (String recId : h.getRecordIds()) changedWorkOrders.add((Id)recId);
            }
        }
        if (!changedWorkOrders.isEmpty()) {
            BillingService.syncFromWorkOrders(changedWorkOrders);
        }
    }
}