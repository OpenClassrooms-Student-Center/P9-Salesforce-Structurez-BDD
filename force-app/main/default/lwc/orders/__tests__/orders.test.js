import { createElement } from 'lwc';
import Orders from 'c/orders';
import getTotal from '@salesforce/apex/MyTeamOrdersController.getActivatedOrdersTotalByAccount';

jest.mock(
    '@salesforce/apex/MyTeamOrdersController.getActivatedOrdersTotalByAccount',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

const RECORD_ID = '001000000000001AAA';

describe('c-orders', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return Promise.resolve();
    }

    function createComponent() {
        const element = createElement('c-orders', { is: Orders });
        element.recordId = RECORD_ID;
        document.body.appendChild(element);
        return element;
    }

    it('affiche le total formate en euros quand la valeur est positive', async () => {
        const element = createComponent();

        getTotal.emit(1500);
        await flushPromises();

        const success = element.shadowRoot.querySelector('.slds-theme_success');
        expect(success).not.toBeNull();

        const formatted = element.shadowRoot.querySelector(
            'lightning-formatted-number'
        );
        expect(formatted).not.toBeNull();
        expect(formatted.value).toBe(1500);
        expect(formatted.formatStyle).toBe('currency');
        expect(formatted.currencyCode).toBe('EUR');
    });

    it("affiche le message d'erreur quand le total vaut 0", async () => {
        const element = createComponent();

        getTotal.emit(0);
        await flushPromises();

        const error = element.shadowRoot.querySelector('.slds-theme_error');
        expect(error).not.toBeNull();

        const success = element.shadowRoot.querySelector('.slds-theme_success');
        expect(success).toBeNull();
    });

    it("affiche le message d'erreur quand le total est null", async () => {
        const element = createComponent();

        getTotal.emit(null);
        await flushPromises();

        const error = element.shadowRoot.querySelector('.slds-theme_error');
        expect(error).not.toBeNull();
    });

    it("affiche le message d'erreur quand l'appel Apex echoue", async () => {
        const element = createComponent();

        getTotal.error({ body: { message: 'Apex error' }, statusCode: 500 });
        await flushPromises();

        const error = element.shadowRoot.querySelector('.slds-theme_error');
        expect(error).not.toBeNull();
    });
});
