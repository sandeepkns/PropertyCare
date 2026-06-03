import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import recentLogs from '@salesforce/apex/IntegrationMonitorController.recentLogs';
import dlqDepth from '@salesforce/apex/IntegrationMonitorController.dlqDepth';
import replayDlq from '@salesforce/apex/IntegrationMonitorController.replayDlq';

const COLUMNS = [
    { label: 'Logged', fieldName: 'Logged_At__c', type: 'date',
      typeAttributes: { hour: '2-digit', minute: '2-digit' } },
    { label: 'Direction', fieldName: 'Direction__c' },
    { label: 'Operation', fieldName: 'Operation__c' },
    { label: 'Outcome', fieldName: 'Outcome__c',
      cellAttributes: { class: { fieldName: 'rowClass' } } },
    { label: 'HTTP', fieldName: 'Status_Code__c', type: 'number' },
    { label: 'Latency (ms)', fieldName: 'Latency_Ms__c', type: 'number' },
    { label: 'Related Id', fieldName: 'Related_Record_Id__c' }
];

export default class IntegrationMonitor extends LightningElement {
    columns = COLUMNS;
    @track outcomeFilter = '';
    depth = 0;

    filterOptions = [
        { label: 'All', value: '' },
        { label: 'Success', value: 'Success' },
        { label: 'Failure', value: 'Failure' },
        { label: 'Retry', value: 'Retry' }
    ];

    wiredLogsResult;
    @wire(recentLogs, { outcomeFilter: '$outcomeFilter' })
    wiredLogs(result) {
        this.wiredLogsResult = result;
        if (result.data) {
            this.rows = result.data.map(r => ({
                ...r,
                rowClass: r.Outcome__c === 'Failure' ? 'slds-text-color_error'
                        : r.Outcome__c === 'Retry' ? 'slds-text-color_warning' : ''
            }));
        }
    }

    @wire(dlqDepth) wiredDepth({ data }) { if (data !== undefined) this.depth = data; }

    get dlqClass() {
        return this.depth > 0 ? 'slds-text-color_error slds-text-heading_large'
                              : 'slds-text-color_success slds-text-heading_large';
    }

    handleFilter(e) { this.outcomeFilter = e.detail.value; }

    handleRefresh() {
        refreshApex(this.wiredLogsResult);
    }

    async handleReplay() {
        try {
            const jobId = await replayDlq();
            this.dispatchEvent(new ShowToastEvent({
                title: 'DLQ replay started', message: 'Batch job ' + jobId,
                variant: 'success' }));
            this.handleRefresh();
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Replay failed',
                message: err?.body?.message || 'Unknown error', variant: 'error' }));
        }
    }
}