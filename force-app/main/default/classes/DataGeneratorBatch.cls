public with sharing class DataGeneratorBatch implements Database.Batchable<Integer>, Database.Stateful {
    private Integer total;
    private Integer perBatch = 10000;
    private Id sampleTenantId;

    public DataGeneratorBatch(Integer total) { this.total = total; }

    public Iterable<Integer> start(Database.BatchableContext bc) {
        // One element per batch chunk
        List<Integer> chunks = new List<Integer>();
        Integer n = (Integer)Math.ceil(total / (Decimal)perBatch);
        for (Integer i = 0; i < n; i++) chunks.add(i);
        // ensure a tenant exists
        List<Tenant__c> t = [SELECT Id FROM Tenant__c LIMIT 1];
        if (t.isEmpty()) {
            Tenant__c nt = new Tenant__c(Name='Seed Tenant', Email__c='seed@pc.test',
                Portal_User_Id__c='seed-tenant', Active__c=true);
            insert nt; sampleTenantId = nt.Id;
        } else { sampleTenantId = t[0].Id; }
        return chunks;
    }

    public void execute(Database.BatchableContext bc, List<Integer> scope) {
        Integer chunkIndex = scope[0];
        List<Service_Request__c> batch = new List<Service_Request__c>();
        String[] priorities = new String[]{'Low','Medium','High','Urgent'};
        String[] cats = new String[]{'Plumbing','Electrical','HVAC','Appliance','General'};
        for (Integer i = 0; i < perBatch; i++) {
            Integer seq = chunkIndex * perBatch + i;
            if (seq >= total) break;
            batch.add(new Service_Request__c(
                Tenant__c    = sampleTenantId,
                External_Id__c = 'SEED-' + seq,
                Category__c  = cats[Math.mod(seq,5)],
                Priority__c  = priorities[Math.mod(seq,4)],
                Status__c    = 'New',
                Source__c    = 'Manual'
            ));
        }
        // bypass event publishing during bulk seed to avoid event storm
        TriggerHandler.bypass('ServiceRequestTriggerHandler');
        insert batch;
        TriggerHandler.clearBypass('ServiceRequestTriggerHandler');
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Seed complete: ' + total + ' Service_Request__c');
    }
}
