/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-19-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class MyTeamOrdersController {

    /**
     * @description : Calcule la somme des montants des commandes "Activated" associées à un compte.
     * @param       accountId : L'ID du compte pour lequel récupérer la somme des commandes.
     * @return      La somme des montants des commandes "Activated" (0 si aucune).
     * @throws      IllegalArgumentException si l'ID fourni est nul.
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getSumOrdersByAccount(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('L\'ID du compte ne peut pas être nul.');
        }

        // Exécution de la requête SOQL pour récupérer la somme des montants des commandes activées
        List<AggregateResult> results = [
            SELECT SUM(TotalAmount) total
            FROM Order
            WHERE AccountId = :accountId AND Status = 'Activated'
            GROUP BY AccountId
            LIMIT 1
        ];

        // Si la liste est vide, aucune commande activée, donc retour de 0
        if (results.isEmpty()) {
            // Aucune commande activée trouvée, retourner 0
            return 0;
            
        }

        // Récupération de la somme du montant
        AggregateResult result = results[0];
        Decimal totalAmount = (Decimal)result.get('total');
        
        // Retourner le montant total ou 0 si null
        return totalAmount != null ? totalAmount : 0;
    }
}
