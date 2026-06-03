trigger WorkOrderChangeEventTrigger on Work_Order__ChangeEvent (after insert) {
    new WorkOrderCDCHandler().handle(Trigger.new);
}