/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger UpdateAccountCA on Order (after update) {
    Set<Id> accountIds = new Set<Id>();
    Set<Id> activatedOrderIds = new Set<Id>();

    for (Order o : Trigger.new) {
        Order oldOrder = Trigger.oldMap.get(o.Id);
        if (o.AccountId != null && o.Status == 'Activated' && oldOrder.Status != 'Activated') {
            accountIds.add(o.AccountId);
            activatedOrderIds.add(o.Id);
        }
    }

    if (accountIds.isEmpty()) return;

    // Récupérer tous les OrderItems liés aux commandes activées des comptes
    List<Order> orders = [
        SELECT Id, AccountId,
               (SELECT Quantity, UnitPrice FROM OrderItems)
        FROM Order
        WHERE Status = 'Activated' AND AccountId IN :accountIds
    ];

    Map<Id, Decimal> revenueByAccount = new Map<Id, Decimal>();

    for (Order ord : orders) {
        Decimal total = 0;
        for (OrderItem item : ord.OrderItems) {
            total += (item.UnitPrice != null ? item.UnitPrice : 0) * (item.Quantity != null ? item.Quantity : 0);
        }

        Decimal currentRevenue = revenueByAccount.containsKey(ord.AccountId) ? revenueByAccount.get(ord.AccountId) : 0;
        revenueByAccount.put(ord.AccountId, currentRevenue + total);
        }

    List<Account> accountsToUpdate = new List<Account>();
    for (Id accId : revenueByAccount.keySet()) {
        accountsToUpdate.add(new Account(Id = accId, ChiffredAffaire__c = revenueByAccount.get(accId)));
    }

    if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate;
    }
}
