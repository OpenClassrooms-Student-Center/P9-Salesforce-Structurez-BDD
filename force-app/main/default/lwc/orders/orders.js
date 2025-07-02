import { LightningElement, api } from 'lwc';
import getSumOrdersByAccount from '@salesforce/apex/MyTeamOrdersController.getSumOrdersByAccount';

export default class Orders extends LightningElement {
    @api recordId;  // Identifiant du compte
    sumOrdersOfCurrentAccount;  // Somme des commandes pour le compte actuel
    isLoading = true;  // Indicateur de chargement
    hasError = false;  // Indicateur d'erreur

    // Méthode appelée lors de la connexion du composant
    connectedCallback() {
        console.log('recordId reçu :', this.recordId);
        this.loadData();  // Charge les données lors de l'initialisation
    }

    // Chargement des données via la méthode Apex
    async loadData() {
        this.isLoading = true;  // Début du chargement

        try {
            // Appel à Apex pour obtenir la somme des commandes
            const result = await getSumOrdersByAccount({ accountId: this.recordId });

            // Si le montant total des commandes est supérieur à 0
            if (result > 0) {
                this.sumOrdersOfCurrentAccount = result;
                this.hasError = false;  // Pas d'erreur
            } else {
                this.sumOrdersOfCurrentAccount = null;
                this.hasError = true;  // Erreur si montant ≤ 0
            }
        } catch (error) {
            // Gestion des erreurs d'Apex
            console.error('Erreur Apex :', error);
            this.hasError = true;  // Marque l'erreur
        } finally {
            this.isLoading = false;  // Fin du chargement
        }
    }
}
