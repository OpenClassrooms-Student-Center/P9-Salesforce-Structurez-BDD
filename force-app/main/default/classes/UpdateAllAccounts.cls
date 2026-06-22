public with sharing class UpdateAllAccounts implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext info) {
        // On ne traite que les comptes ayant au moins une commande Activated.
        // Pour un audit/reinit complet, retirer la sous-requete.
        return Database.getQueryLocator(
            'SELECT Id FROM Account ' +
            'WHERE Id IN (SELECT AccountId FROM Order WHERE Status = \'' +
            AccountCAService.ACTIVATED_STATUS + '\')'
        );
    }

    public void execute(Database.BatchableContext info, List<Account> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        Set<Id> accountIds = (new Map<Id, Account>(scope)).keySet();
        AccountCAService.recalculateForAccounts(accountIds);
    }

    public void finish(Database.BatchableContext info) {
        System.debug(LoggingLevel.INFO,
            'UpdateAllAccounts batch termine. Job Id: ' + info.getJobId());
    }
}
