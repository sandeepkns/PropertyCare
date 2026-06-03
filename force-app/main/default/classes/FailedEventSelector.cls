public with sharing class FailedEventSelector {
    
    /**
     * Big Object SOQL constraints:
     * We cannot filter directly on Resolved__c or Attempts__c because they are not index members.
     * Instead, we query a safe batch size ordered by our index, and the batch engine/handler 
     * handles filtering the subset in-memory.
     */
    public static List<Failed_Event__b> pendingForReplay(Integer rowLimit) {
        // We drop the invalid WHERE clause entirely to make the query platform-legal.
        // This scans the Big Object records safely up to your specified processing limit.
        return [
            SELECT Event_Uuid__c, Failed_At__c, Request_External_Id__c,
                   Payload__c, Failure_Reason__c, Attempts__c, Resolved__c
            FROM Failed_Event__b
            LIMIT :rowLimit
        ];
    }

    public static Integer unresolvedCount() {
        // Big Objects do not support COUNT(). We pull rows and calculate the collection size.
        // Since we cannot filter by Resolved__c directly in the database, we query the chunk 
        // and filter inside an inner loop memory block.
        List<Failed_Event__b> allRows = [
            SELECT Resolved__c 
            FROM Failed_Event__b 
            LIMIT 10000
        ];
        
        Integer unresolvedCounter = 0;
        for (Failed_Event__b row : allRows) {
            if (row.Resolved__c == 'false') {
                unresolvedCounter++;
            }
        }
        return unresolvedCounter;
    }
}