// Renders the case description with its original formatting (Skyward support widget, 2019)
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import DESCRIPTION from '@salesforce/schema/Case.Description';

export default class SkyCaseNotes extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [DESCRIPTION] })
    wiredCase({ data }) {
        if (data) {
            this.template.querySelector('div').innerHTML = getFieldValue(data, DESCRIPTION);
        }
    }
}
