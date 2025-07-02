/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class UpdateAllAccounts implements Database.Batchable<sObject> {

    /**
     * Méthode start : récupère les comptes liés à des commandes "Activated"
     */
    global Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('[UpdateAllAccounts] Démarrage du batch : récupération des comptes avec commandes "Activated".');
        
        String query = 'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Order WHERE Status = \'Activated\')';
        return Database.getQueryLocator(query);
    }

    /**
     * Méthode execute : pour chaque lot de comptes, calcule la somme des montants des commandes "Activated" 
     * et met à jour le champ ChiffreAffaire__c sur chaque compte
     */
    global void execute(Database.BatchableContext context, List<Account> scope) {
        System.debug('[UpdateAllAccounts] Exécution du batch pour ' + scope.size() + ' comptes.');

        // Collecte des IDs des comptes dans le scope
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }
        System.debug('[UpdateAllAccounts] Account IDs dans le scope : ' + accountIds);

        // Agrégation des montants totaux des commandes "Activated" par compte
        Map<Id, Decimal> revenueByAccount = new Map<Id, Decimal>();
        AggregateResult[] aggResults = [
            SELECT AccountId, SUM(TotalAmount) totalRevenue
            FROM Order
            WHERE Status = 'Activated' AND AccountId IN :accountIds
            GROUP BY AccountId
        ];
        System.debug('[UpdateAllAccounts] Résultats agrégés récupérés : ' + aggResults.size());

        for (AggregateResult ar : aggResults) {
            Id accId = (Id) ar.get('AccountId');
            Decimal totalRev = (Decimal) ar.get('totalRevenue');
            revenueByAccount.put(accId, totalRev);
            System.debug('[UpdateAllAccounts] Compte ' + accId + ' chiffre d\'affaires calculé : ' + totalRev);
        }

        // Préparation de la liste des comptes à mettre à jour avec le chiffre d'affaires calculé
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : scope) {
            Decimal calculatedRevenue = revenueByAccount.containsKey(acc.Id) ? revenueByAccount.get(acc.Id) : 0;
            acc.ChiffredAffaire__c = calculatedRevenue;
            accountsToUpdate.add(acc);
            System.debug('[UpdateAllAccounts] Mise à jour compte ' + acc.Id + ' avec chiffre d\'affaires = ' + calculatedRevenue);
        }

        // Mise à jour des comptes en base
        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate;
                System.debug('[UpdateAllAccounts] Mise à jour de ' + accountsToUpdate.size() + ' comptes effectuée avec succès.');
            } catch (DmlException e) {
                System.debug('[UpdateAllAccounts] Erreur DML lors de la mise à jour des comptes : ' + e.getMessage());
            }
        } else {
            System.debug('[UpdateAllAccounts] Aucun compte à mettre à jour dans ce lot.');
        }
    }

    /**
     * Méthode finish : planifie le batch pour une exécution récurrente tous les dimanches à minuit,
     * sauf si on est en mode test, et en évitant les doublons de planification.
     */
    global void finish(Database.BatchableContext context) {
        System.debug('[UpdateAllAccounts] Batch terminé.');

        if (!Test.isRunningTest()) {
            String cronExpression = '0 0 0 ? * SUN'; // Tous les dimanches à minuit
            String jobName = 'UpdateAllAccountsBatchScheduler';

            // Vérification si un job similaire est déjà planifié
            List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
            if (jobs.isEmpty()) {
                try {
                    String jobId = System.schedule(jobName, cronExpression, new UpdateAllAccountsScheduler());
                    System.debug('[UpdateAllAccounts] Job planifié : ' + jobId);
                } catch (Exception e) {
                    System.debug('[UpdateAllAccounts] Erreur de planification du job : ' + e.getMessage());
                }
            } else {
                System.debug('[UpdateAllAccounts] Job déjà planifié, pas de nouvelle planification effectuée.');
            }
        } else {
            System.debug('[UpdateAllAccounts] Mode test détecté, planification non effectuée.');
        }
    }
}
