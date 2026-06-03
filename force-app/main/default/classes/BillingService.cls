public with sharing class BillingService {
    public static void syncFromWorkOrders(Set<Id> woIds) {
        Map<Id,Work_Order__c> wos = new Map<Id,Work_Order__c>(WorkOrderSelector.byIds(woIds));
        Map<Id,Billing_Statement__c> existing = new Map<Id,Billing_Statement__c>();
        for (Billing_Statement__c b : BillingSelector.byWorkOrderIds(woIds)) {
            existing.put(b.Work_Order__c, b);
        }
        List<Billing_Statement__c> upserts = new List<Billing_Statement__c>();
        for (Work_Order__c wo : wos.values()) {
            if (wo.Status__c == 'Completed') {
                Billing_Statement__c b = existing.containsKey(wo.Id)
                    ? existing.get(wo.Id)
                    : new Billing_Statement__c(Work_Order__c = wo.Id, Tenant__c = wo.Tenant__c);
                b.Amount__c = wo.Amount__c;
                b.Billing_Status__c = 'Issued';
                b.Issued_Date__c = Date.today();
                b.Statement_Period__c = String.valueOf(Date.today().year())
                    + '-' + String.valueOf(Date.today().month()).leftPad(2,'0');
                upserts.add(b);
            } else if (wo.Status__c == 'Cancelled' && existing.containsKey(wo.Id)) {
                Billing_Statement__c b = existing.get(wo.Id);
                if (b.Billing_Status__c == 'Draft') { b.Billing_Status__c = 'Void'; upserts.add(b); }
            }
        }
        if (!upserts.isEmpty()) upsert upserts;
    }
}