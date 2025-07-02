/**
 * @description : Planificateur Apex pour exécuter le batch UpdateAllAccounts 
 *                de manière récurrente (ex : chaque dimanche à minuit).
 * @author      : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified on : 05-05-2025
 * @last modified by : ChangeMeIn@UserSettingsUnder.SFDoc
 */
global class UpdateAllAccountsScheduler implements Schedulable {

    global void execute(SchedulableContext context) {
        System.debug('[UpdateAllAccountsScheduler] Exécution du job planifié.');

        // Instanciation du batch pour mise à jour des comptes
        UpdateAllAccounts batchJob = new UpdateAllAccounts();

        // Exécution du batch avec une taille de lot de 200 (valeur recommandée)
        Database.executeBatch(batchJob, 200);

        System.debug('[UpdateAllAccountsScheduler] Batch UpdateAllAccounts lancé.');
    }
}
