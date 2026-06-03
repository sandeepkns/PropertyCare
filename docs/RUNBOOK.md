# PropertyCare System Operations Runbook

## 1. Background Automation Management
The asynchronous retry and data cleanup engines are scheduled using continuous system CRON triggers.

### Registering the Hourly Recovery Batch
Execute this line inside an Anonymous Apex execution block via the Developer Console or CLI to initiate the hourly self-healing loop:
```apex
System.schedule('PropertyCare DLQ Hourly Replayer', '0 0 * * * ?', new DlqReplayScheduler());