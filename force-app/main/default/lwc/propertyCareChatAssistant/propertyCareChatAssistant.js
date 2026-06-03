import { LightningElement, track } from 'lwc';
import processMessage from '@salesforce/apex/PropertyCareAgentController.processMessage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PropertyCareChatAssistant extends LightningElement {
    @track tenantId = '';
    @track userInput = '';
    @track isBotLoading = false;
    @track messages = [
        { id: 1, sender: 'System', text: 'Please select an Active Tenant record context above to boot up your secure chat session.', cssClass: 'slds-text-color_weak slds-m-bottom_x-small' }
    ];

    handleTenantChange(event) {
        this.tenantId = event.detail.recordId;
        this.messages = [
            { id: Date.now(), sender: 'Assistant', text: 'Secure tenant channel locked. How can I help you with your property management requests today?', cssClass: 'slds-chat-message_inbound slds-m-bottom_x-small slds-text-color_success' }
        ];
    }

    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    async sendMessage() {
        if (!this.tenantId) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Security Boundary Missing', message: 'You must designate a Tenant record context before testing the interface.', variant: 'warning' }));
            return;
        }
        if (!this.userInput.trim()) return;

        const currentUserText = this.userInput;
        this.messages = [...this.messages, { id: 'user-' + Date.now(), sender: 'Tenant', text: currentUserText, cssClass: 'slds-text-align_right slds-m-bottom_x-small' }];
        this.userInput = '';
        this.isBotLoading = true;

        try {
            // Handoff properties over Apex Wire Method Layer
            const result = await processMessage({ userInput: currentUserText, tenantId: this.tenantId });
            
            let messageStyle = result.isEscalated 
                ? 'slds-m-bottom_x-small slds-p-around_x-small slds-theme_alert-texture slds-text-color_error' 
                : 'slds-chat-message_inbound slds-m-bottom_x-small slds-text-color_indigo';

            this.messages = [...this.messages, { id: 'bot-' + Date.now(), sender: 'Assistant', text: result.message, cssClass: messageStyle }];
        } catch (error) {
            this.messages = [...this.messages, { id: 'err-' + Date.now(), sender: 'Error', text: 'Failed to extract an answer. Check your console registers.', cssClass: 'slds-text-color_error slds-m-bottom_x-small' }];
        } finally {
            this.isBotLoading = false;
            // Handle scrolling down safely after rendering completes
            setTimeout(() => {
                const scrollContainer = this.template.querySelector('.chat-window');
                if (scrollContainer) scrollContainer.scrollTop = scrollContainer.scrollHeight;
            }, 50);
        }
    }
}