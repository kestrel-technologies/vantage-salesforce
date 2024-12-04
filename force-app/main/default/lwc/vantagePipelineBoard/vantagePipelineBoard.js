import { LightningElement, wire } from 'lwc';
import getBoard from '@salesforce/apex/VantagePipelineBoardController.getBoard';

export default class VantagePipelineBoard extends LightningElement {
    columns = [];
    error;

    @wire(getBoard)
    wiredBoard({ data, error }) {
        if (data) {
            this.columns = data.map((col) => ({
                ...col,
                cards: col.cards.map((card) => ({ ...card, url: '/lightning/r/Opportunity/' + card.id + '/view' }))
            }));
            this.error = undefined;
        } else if (error) {
            this.columns = [];
            this.error = error.body ? error.body.message : 'Could not load pipeline';
        }
    }
}
