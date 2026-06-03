trigger ServiceRequestEventTrigger on service_request_event__e (after insert) {
    new ServiceRequestEventTriggerHandler().handle(Trigger.new);
}