import { LightningElement, api, track } from 'lwc';
import getSumOrdersByAccount from '@salesforce/apex/MyTeamOrdersController.getSumOrdersByAccount';

export default class OrderSummaryLwc extends LightningElement {
    @api recordId;
    @track sumOrdersOfCurrentAccount = 0;
    @track hasError = false;
    connectedCallback() {
        this.fetchSumOrders();
    }
    fetchSumOrders() {
        getSumOrdersByAccount({ accountId: this.recordId })
            .then(result => {
                this.sumOrdersOfCurrentAccount = result;
                this.hasError = !result || result <= 0;
            })
            .catch(() => {
                this.hasError = true;
   });
    }
}
