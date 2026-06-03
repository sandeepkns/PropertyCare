public with sharing class BillingService {
    
    /**
     * @description Core execution method. The annotation below makes this signature 
     * instantly searchable and callable inside Flow Builder.
     * @param woIds List of Work Order record IDs coming from the Flow engine context.
     */
    @InvocableMethod(
        label='Sync Billing From Work Orders' 
        description='Triggers the billing engine synchronization matrix for completed or cancelled work orders.'
        category='Billing'
    )
    public static void syncFromWorkOrders(List<Id> woIds) {
        if (woIds == null || woIds.isEmpty()) return;

        // Convert the list to a set to feed your internal selector layer query structures
        Set<Id> woIdSet = new Set<Id>(woIds);
        
        // Fetch active Work Order field details through standard project Selector patterns
        Map<Id, Work_Order__c> wos = new Map<Id, Work_Order__c>(WorkOrderSelector.byIds(woIdSet));
        
        // Build a tracking map of existing Billing Statement records matching these Work Orders to prevent duplication
        Map<Id, Billing_Statement__c> existing = new Map<Id, Billing_Statement__c>();
        for (Billing_Statement__c b : BillingSelector.byWorkOrderIds(woIdSet)) {
            existing.put(b.Work_Order__c, b);
        }
        
        List<Billing_Statement__c> upserts = new List<Billing_Statement__c>();
        
        for (Work_Order__c wo : wos.values()) {
            if (wo.Status__c == 'Completed') {
                // If a statement already exists, update it; otherwise, instantiate a clean child record link
                Billing_Statement__c b = existing.containsKey(wo.Id)
                    ? existing.get(wo.Id)
                    : new Billing_Statement__c(Work_Order__c = wo.Id, Tenant__c = wo.Tenant__c);
                
                b.Amount__c = wo.Amount__c;
                b.Billing_Status__c = 'Issued';
                b.Issued_Date__c = Date.today();
                b.Statement_Period__c = String.valueOf(Date.today().year())
                    + '-' + String.valueOf(Date.today().month()).leftPad(2, '0');
                
                upserts.add(b);
                
            } else if (wo.Status__c == 'Cancelled' && existing.containsKey(wo.Id)) {
                Billing_Statement__c b = existing.get(wo.Id);
                // Security Guardrail: Only cancel or void records that are currently in a Draft operational state
                if (b.Billing_Status__c == 'Draft') { 
                    b.Billing_Status__c = 'Void'; 
                    upserts.add(b); 
                }
            }
        }
        
        // Persist transaction data back to the database safely
        if (!upserts.isEmpty()) {
            upsert upserts;
        }
    }

    /**
     * @description METADATA OVERLOAD ADAPTER: Unblocks your Change Data Capture (CDC) 
     * trigger handler by natively accepting a Set<Id>, packaging it into a 
     * List<Id>, and routing it down to the core logic loop.
     * @param woIdSet Set of Work Order record IDs coming from Trigger/CDC context.
     */
    public static void syncFromWorkOrders(Set<Id> woIdSet) {
        if (woIdSet == null || woIdSet.isEmpty()) return;
        
        // Convert the Set natively into a new List instance and redirect execution to the primary method
        syncFromWorkOrders(new List<Id>(woIdSet));
    }
}