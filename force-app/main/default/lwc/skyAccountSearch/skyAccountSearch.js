import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import search from '@salesforce/apex/SKY_AccountSearchController.search';

export default class SkyAccountSearch extends NavigationMixin(LightningElement) {
    searchTerm = '';
    accounts;
    error;

    @wire(search, { searchTerm: '$searchTerm' })
    wiredAccounts({ data, error }) {
        if (data) {
            this.accounts = data.map((a) => ({ ...a, url: '/' + a.Id }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
        }
    }

    handleChange(event) {
        this.searchTerm = event.target.value;
    }

    openAccount(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: event.currentTarget.dataset.id, objectApiName: 'Account', actionName: 'view' }
        });
    }
}
