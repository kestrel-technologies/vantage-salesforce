import { LightningElement, api } from 'lwc';
import exportForAccount from '@salesforce/apex/SKY_ContactExportController.exportForAccount';

const COLUMNS = ['Name', 'Title', 'Email', 'Phone', 'MobilePhone'];

function csvCell(value) {
    const s = value === undefined || value === null ? '' : String(value);
    return '"' + s.replace(/"/g, '""') + '"';
}

export default class SkyContactExport extends LightningElement {
    @api recordId;
    message;

    handleExport() {
        exportForAccount({ accountId: this.recordId })
            .then((contacts) => {
                const lines = [COLUMNS.join(',')];
                contacts.forEach((c) => lines.push(COLUMNS.map((col) => csvCell(c[col])).join(',')));
                const link = document.createElement('a');
                link.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(lines.join('\n'));
                link.download = 'contacts.csv';
                link.click();
                this.message = contacts.length + ' contacts exported.';
            })
            .catch((e) => {
                this.message = e && e.body ? e.body.message : 'Export failed';
            });
    }
}
