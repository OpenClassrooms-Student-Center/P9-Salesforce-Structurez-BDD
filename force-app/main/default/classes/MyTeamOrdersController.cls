public without sharing class MyTeamOrdersController {
  @AuraEnabled
    public static Decimal getSumOrdersByAccount(Id accountId) {
        return OrderService.getAccountCA(accountId);
    }
}

// test 2 3 4 5 6 7 8 9 8 9 n
