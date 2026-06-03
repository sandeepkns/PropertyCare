public with sharing class GenerateSOAAction {
    public class Request {
        @InvocableVariable(required=true) public Id tenantId;
        @InvocableVariable public String period; // e.g. 2026-06
    }
    public class Result {
        @InvocableVariable public Decimal totalDue;
        @InvocableVariable public Integer lineCount;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Generate Statement of Account')
    public static List<Result> generate(List<Request> requests) {
        List<Result> out = new List<Result>();
        for (Request r : requests) {
            Result res = new Result();
            List<Billing_Statement__c> lines = BillingSelector.byTenant(r.tenantId, r.period);
            Decimal total = 0;
            for (Billing_Statement__c b : lines) {
                if (b.Amount__c != null) total += b.Amount__c;
            }
            res.lineCount = lines.size();
            res.totalDue = total;
            res.message = lines.isEmpty()
                ? 'No statements found for that period.'
                : 'Total due: ' + total + ' across ' + lines.size() + ' item(s).';
            out.add(res);
        }
        return out;
    }
}