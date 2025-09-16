public without sharing class OrderTriggerHandler {

    public static void calculateNetAmount(List<Order> orders) {
        for (Order o : orders) {
            if (o.TotalAmount != null && o.ShipmentCost__c != null) {
                o.NetAmount__c = o.TotalAmount - o.ShipmentCost__c;
            } else {
                o.NetAmount__c = 0;
            }
        }
    }

    public static void updateAccountCA(List<Order> newOrders, Map<Id, Order> oldMap) {
        Set<Id> accountIds = new Set<Id>();

        for (Order o : newOrders) {
            Order oldOrder = oldMap.get(o.Id);
            if (o.AccountId != null && o.Status != oldOrder.Status) {
                accountIds.add(o.AccountId);
            }
        }

        if (accountIds.isEmpty()) return;

        Map<Id, Decimal> caMap = OrderSelector.getActivatedOrdersSumByAccount(accountIds);

        List<Account> accountsToUpdate = new List<Account>();
        for (Id accId : caMap.keySet()) {
            accountsToUpdate.add(new Account(
                Id = accId,
                Chiffre_d_affaire__c = caMap.get(accId)
            ));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}