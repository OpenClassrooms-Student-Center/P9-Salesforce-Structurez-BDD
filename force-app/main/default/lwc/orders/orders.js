import { LightningElement, api, wire } from 'lwc';
import getTotal from '@salesforce/apex/MyTeamOrdersController.getActivatedOrdersTotalByAccount';

export default class Orders extends LightningElement {

    @api recordId;

    total;
    error;

    @wire(getTotal, { accountId: '$recordId' })
    wiredTotal({ data, error }) {
        if (data !== undefined) {
            this.total = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.total = undefined;
        }
    }

    get hasTotal() {
        return this.total !== undefined && this.total !== null && this.total > 0;
    }
}
