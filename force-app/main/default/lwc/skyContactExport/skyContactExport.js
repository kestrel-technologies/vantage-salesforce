import { LightningElement, api } from 'lwc';
import exportContacts from '@salesforce/apex/SKY_ContactExportController.exportContacts';

const COLUMNS = ['Name', 'Title', 'Email', 'Phone', 'MobilePhone', 'MailingCity'];

export default class SkyContactExport extends LightningElement {
    @api recordId;
    busy = false;
    message;

    async handleExport() {
        this.busy = true;
        this.message = undefined;
        try {
            const rows = await exportContacts({ accountId: this.recordId });
            const lines = [COLUMNS.join(',')].concat(rows.map((r) => COLUMNS.map((c) => r[c] || '').join(',')));
            const link = document.createElement('a');
            link.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(lines.join('\n'));
            link.download = 'contacts-' + this.recordId + '.csv';
            link.click();
            this.message = rows.length + ' contacts exported.';
        } catch (e) {
            this.message = 'Export failed: ' + (e.body ? e.body.message : e.message);
        } finally {
            this.busy = false;
        }
    }
}
