public with sharing class OrderTriggerHandler {

    public static void run() {
        if (Trigger.isAfter && Trigger.isInsert) {
            handleAfterInsert(Trigger.new);
        } else if (Trigger.isAfter && Trigger.isUpdate) {
            handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isAfter && Trigger.isDelete) {
            handleAfterDelete(Trigger.old);
        } else if (Trigger.isAfter && Trigger.isUndelete) {
            handleAfterInsert(Trigger.new);
        }
    }

    private static void handleAfterInsert(List<Order> newOrders) {
        Set<Id> accountIds = new Set<Id>();
        for (Order o : newOrders) {
            if (o.AccountId != null && o.Status == AccountCAService.ACTIVATED_STATUS) {
                accountIds.add(o.AccountId);
            }
        }
        AccountCAService.recalculateForAccounts(accountIds);
    }

    private static void handleAfterUpdate(List<Order> newOrders, Map<Id, Order> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldMap.get(newOrder.Id);

            Boolean statusChanged  = newOrder.Status      != oldOrder.Status;
            Boolean amountChanged  = newOrder.TotalAmount != oldOrder.TotalAmount;
            Boolean accountChanged = newOrder.AccountId   != oldOrder.AccountId;

            if (newOrder.AccountId != null
                && (statusChanged
                    || ((accountChanged || amountChanged)
                        && newOrder.Status == AccountCAService.ACTIVATED_STATUS))) {
                accountIds.add(newOrder.AccountId);
            }
            if (accountChanged
                && oldOrder.AccountId != null
                && oldOrder.Status == AccountCAService.ACTIVATED_STATUS) {
                accountIds.add(oldOrder.AccountId);
            }
        }
        AccountCAService.recalculateForAccounts(accountIds);
    }

    private static void handleAfterDelete(List<Order> oldOrders) {
        Set<Id> accountIds = new Set<Id>();
        for (Order o : oldOrders) {
            if (o.AccountId != null && o.Status == AccountCAService.ACTIVATED_STATUS) {
                accountIds.add(o.AccountId);
            }
        }
        AccountCAService.recalculateForAccounts(accountIds);
    }
}
