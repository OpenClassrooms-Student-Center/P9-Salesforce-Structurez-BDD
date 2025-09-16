public class OrderService {
    public static Decimal getAccountCA(Id accountId){
        Decimal total = OrderSelector.getActivatedOrdersTotalByAccount(accountId);
        return total == null ? 0 : total;
    }
    public static void updateAccountsCA(Set<Id> accountIds){
        if(accountIds.isEmpty()) return;

        Map<Id, Decimal> caMap = OrderSelector.getActivatedOrdersSumByAccount(accountIds);
        List<Account> comptesToUpdate = new List<Account>();
        for(Id accId : caMap.keySet()){
            comptesToUpdate.add(new Account(Id = accId, Chiffre_d_affaire__c = caMap.get(accId)));
        }
        if(!comptesToUpdate.isEmpty()){
            update comptesToUpdate;
        }
    }
}