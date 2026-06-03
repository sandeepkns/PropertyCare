public with sharing class DlqReplayScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DlqReplayBatch(), 200);
    }
    // System.schedule('PC DLQ Replay','0 0 * * * ?', new DlqReplayScheduler());
}
