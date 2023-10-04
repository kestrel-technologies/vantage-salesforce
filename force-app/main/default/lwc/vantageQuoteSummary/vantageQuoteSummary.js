import { LightningElement, api, wire } from 'lwc';
import getSummary from '@salesforce/apex/VantageQuoteSummaryController.getSummary';

export default class VantageQuoteSummary extends LightningElement {
    @api recordId;
    summary;
    error;

    @wire(getSummary, { opportunityId: '$recordId' })
    wiredSummary({ data, error }) {
        if (data) {
            this.summary = data;
            this.error = undefined;
        } else if (error) {
            this.summary = undefined;
            this.error = error.body ? error.body.message : 'Could not load quotes';
        }
    }

    get hasQuotes() {
        return this.summary && this.summary.quotes && this.summary.quotes.length > 0;
    }
}
