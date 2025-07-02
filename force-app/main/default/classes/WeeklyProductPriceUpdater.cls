/**
 * @description       : Batch qui met à jour les prix des produits actifs (PricebookEntry)
 *                      uniquement s'ils ne sont pas liés à une commande activée (OrderItem -> Order.Status = 'Activated').
 *                      Il divise le prix par 10 si le prix est > 0, et active l'utilisation du prix standard.
 *                      Le batch peut être lancé manuellement ou programmé chaque lundi à minuit.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-18-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class WeeklyProductPriceUpdater implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    // Étape 1 : Requête des enregistrements à traiter
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 
            'SELECT Id, UnitPrice ' +
            'FROM PricebookEntry ' +
            'WHERE IsActive = TRUE ' +
            'AND Id NOT IN (' +
            '    SELECT PricebookEntryId ' +
            '    FROM OrderItem ' +
            '    WHERE Order.Status = \'Activated\'' +
            ')';
        
        System.debug('🔍 Début du batch - Requête exécutée : ' + query);
        return Database.getQueryLocator(query);
    }

    // Étape 2 : Traitement des enregistrements
    global void execute(Database.BatchableContext BC, List<PricebookEntry> scope) {
        List<PricebookEntry> priceEntriesToUpdate = new List<PricebookEntry>();
        Integer totalAnalyzed = 0;
        Integer totalUpdated = 0;

        for (PricebookEntry entry : scope) {
            totalAnalyzed++;
            System.debug('➡️ Analyse de PricebookEntry : Id=' + entry.Id + ', UnitPrice=' + entry.UnitPrice);

            if (entry.UnitPrice == null || entry.UnitPrice <= 0) {
                System.debug('⏭️ Prix nul ou négatif, ignoré.');
                continue;
            }

            Decimal newPrice = (entry.UnitPrice + 2).setScale(2, RoundingMode.HALF_UP);

            if (newPrice != entry.UnitPrice) {
                entry.UnitPrice = newPrice;
                entry.UseStandardPrice = false;
                priceEntriesToUpdate.add(entry);
                totalUpdated++;
                System.debug('✅ Nouveau prix appliqué : ' + newPrice);
            }
        }

        System.debug('🔢 Analyse terminée : ' + totalAnalyzed + ' entrées traitées, ' + totalUpdated + ' mises à jour.');

        if (!priceEntriesToUpdate.isEmpty()) {
            try {
                update priceEntriesToUpdate;
                System.debug('🛠️ Mise à jour réussie de ' + priceEntriesToUpdate.size() + ' entrées.');
            } catch (Exception e) {
                System.debug('❌ Erreur lors de la mise à jour : ' + e.getMessage());
            }
        } else {
            System.debug('ℹ️ Aucune mise à jour nécessaire dans ce lot.');
        }
    }

    // Étape 3 : Fin du batch
    global void finish(Database.BatchableContext BC) {
        System.debug('✅ Batch terminé.');
    }

    // Méthode pour planifier automatiquement le batch chaque lundi à minuit
    public static void scheduleWeeklyJob() {
        String cronExp = '0 0 0 ? * MON';
        System.schedule('Weekly Product Price Update', cronExp, new WeeklyProductPriceUpdater());
        System.debug('📅 Batch planifié pour s\'exécuter chaque lundi à minuit.');
    }

    // Méthode appelée par le planificateur (Scheduler)
    global void execute(SchedulableContext sc) {
        System.debug('🚀 Exécution planifiée déclenchée.');
        Database.executeBatch(new WeeklyProductPriceUpdater(), 200);
    }
}
