/**
 * @description       : Déclencheur pour calculer le montant net d'une commande (NetAmount__c) lors de la mise à jour.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 */
trigger CalculMontant on Order (before insert,before update) {
    // Log d'entrée pour indiquer l'exécution du déclencheur
    System.debug('Déclencheur "CalculMontant" exécuté pour ' + trigger.new.size() + ' enregistrements.');

    // Itération sur les commandes mises à jour
    for (Order newOrder : trigger.new) {
        try {
            // Initialisation des valeurs pour Total_Amount__c et ShipmentCost__c
            Decimal total = (newOrder.TotalAmount != null) ? newOrder.TotalAmount : 0;
            Decimal shipment = (newOrder.ShipmentCost__c != null) ? newOrder.ShipmentCost__c : 0;

            // Calcul du NetAmount et mise à jour du champ
            newOrder.NetAmount__c = total - shipment;

            // Log pour vérifier le résultat du calcul
            System.debug('Commande ' + newOrder.Id + ': NetAmount calculé = ' + newOrder.NetAmount__c);
        } catch (Exception e) {
            // Gestion des erreurs et log d'erreur
            System.debug('Erreur lors du calcul du NetAmount pour la commande ' + newOrder.Id + ': ' + e.getMessage());
        }
    }

    // Log de fin pour indiquer la fin du traitement
    System.debug('Fin du traitement du déclencheur "CalculMontant".');
}