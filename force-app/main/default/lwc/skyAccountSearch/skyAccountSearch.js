import { LightningElement, track } from 'lwc';
import search from '@salesforce/apex/SKY_AccountSearchController.search';

const DELAY = 300;

export default class SkyAccountSearch extends LightningElement {
    searchTerm = '';
    @track accounts = [];
    error;

    get hasResults() {
        return this.accounts.length > 0;
    }

    handleChange(event) {
        this.searchTerm = event.target.value;
        window.clearTimeout(this.timer);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timer = window.setTimeout(() => this.runSearch(), DELAY);
    }

    runSearch() {
        if (!this.searchTerm || this.searchTerm.length < 2) {
            this.accounts = [];
            return;
        }
        search({ searchTerm: this.searchTerm })
            .then((rows) => {
                this.accounts = rows.map((r) => ({ ...r, url: '/lightning/r/Account/' + r.Id + '/view' }));
                this.error = undefined;
            })
            .catch((e) => {
                this.accounts = [];
                this.error = e && e.body ? e.body.message : 'Search failed';
            });
    }
}
