public class UpdateAccountsCABatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id FROM Account
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope){
        Set<Id> accountIds = new Set<Id>();
        for(Account a : scope){
            accountIds.add(a.Id);
        }
        OrderService.updateAccountsCA(accountIds);
    }

    public void finish(Database.BatchableContext bc){
      
    }
}