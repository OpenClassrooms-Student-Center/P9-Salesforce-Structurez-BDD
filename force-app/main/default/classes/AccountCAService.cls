public with sharing class AccountCAService {

    public static final String ACTIVATED_STATUS = 'Activated';

    public static void recalculateForAccounts(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> caByAccount = OrderSelector.getTotalsByAccount(
            accountIds,
            ACTIVATED_STATUS
        );

        List<Account> toUpdate = new List<Account>();
        for (Id accId : accountIds) {
            Decimal ca = caByAccount.containsKey(accId) ? caByAccount.get(accId) : 0;
            toUpdate.add(new Account(
                Id = accId,
                Chiffre_d_affaire__c = ca
            ));
        }
        update toUpdate;
    }
}
