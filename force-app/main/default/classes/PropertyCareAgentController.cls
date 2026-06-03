public with sharing class PropertyCareAgentController {

    public class ChatResponse {
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Boolean isEscalated { get; set; }
    }

    @AuraEnabled
    public static ChatResponse processMessage(String userInput, Id tenantId) {
        ChatResponse res = new ChatResponse();
        res.isEscalated = false;

        // 1. Guardrail Validation: Enforce Tenant Security Isolation Boundary
        if (tenantId == null) {
            res.message = 'System Error: Unauthenticated session context. Access Denied.';
            return res;
        }

        try {
            String lowerInput = userInput.toLowerCase();

            // 2. Topic 1: Booking Routing Strategy
            if (lowerInput.contains('book') || lowerInput.contains('repair') || lowerInput.contains('fix')) {
                BookServiceSlotAction.Request req = new BookServiceSlotAction.Request();
                req.tenantId = tenantId;
                req.category = parseCategory(lowerInput);
                req.priority = lowerInput.contains('urgent') ? 'Urgent' : (lowerInput.contains('high') ? 'High' : 'Medium');
                req.description = userInput;
                req.requestedSlot = System.now().addDays(1); // Defaulting to tomorrow's slot window

                List<BookServiceSlotAction.Result> results = BookServiceSlotAction.book(new List<BookServiceSlotAction.Request>{req});
                res.message = results[0].message + ' Tracking Reference Number: ' + results[0].requestNumber;
            } 
            
            // 3. Topic 2: Status Routing Strategy
            else if (lowerInput.contains('status') || lowerInput.contains('where') || lowerInput.contains('track')) {
                String identifier = parseIdentifier(userInput);
                if (String.isBlank(identifier)) {
                    res.message = 'Please provide your Request Name or External Reference Key so I can track your ticket.';
                    return res;
                }

                RequestStatusAction.Request req = new RequestStatusAction.Request();
                req.tenantId = tenantId;
                req.requestIdentifier = identifier;

                List<RequestStatusAction.Result> results = RequestStatusAction.status(new List<RequestStatusAction.Request>{req});
                res.message = results[0].message;
            } 
            
            // 4. Topic 3: Billing Statement Routing Strategy
            else if (lowerInput.contains('statement') || lowerInput.contains('billing') || lowerInput.contains('account') || lowerInput.contains('due')) {
                GenerateSOAAction.Request req = new GenerateSOAAction.Request();
                req.tenantId = tenantId;
                req.period = String.valueOf(Date.today().year()) + '-' + String.valueOf(Date.today().month()).leftPad(2, '0');

                List<GenerateSOAAction.Result> results = GenerateSOAAction.generate(new List<GenerateSOAAction.Request>{req});
                res.message = results[0].message;
            } 
            
            // 5. Section 7.6 Guardrail Escalation: Low Confidence / Out of Scope Routing
            else {
                res.isEscalated = true;
                res.message = 'I cannot confidently resolve that request within my architectural scope. Redirecting this conversation thread to a live support representative queue...';
                
                IntegrationLogger.logNow(
                    IntegrationLogger.Direction.Internal, 'Agent_Escalation', tenantId, 200, 
                    IntegrationLogger.Outcome.Failure, 0, 'Out of scope input: ' + userInput
                );
            }

        } catch (Exception ex) {
            res.message = 'An operational error occurred while evaluating your request: ' + ex.getMessage();
        }

        return res;
    }

    private static String parseCategory(String input) {
        if (input.contains('plumb') || input.contains('water') || input.contains('leak')) return 'Plumbing';
        if (input.contains('light') || input.contains('power') || input.contains('electric')) return 'Electrical';
        if (input.contains('ac ') || input.contains('heat') || input.contains('hvac')) return 'HVAC';
        if (input.contains('fridge') || input.contains('washer') || input.contains('appliance')) return 'Appliance';
        return 'General';
    }

    private static String parseIdentifier(String input) {
        // Regex pattern search matches standard SR-XXXXXX formats or AGENT-XXXX string tokens cleanly
        Pattern p = Pattern.compile('(?i)(SR-\\d+|AGENT-[a-zA-Z0-9\\-]+)');
        Matcher m = p.matcher(input);
        return m.find() ? m.group(1) : '';
    }
}