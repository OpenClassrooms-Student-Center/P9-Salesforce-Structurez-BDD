public with sharing class MyTeamOrdersController {

    @AuraEnabled(cacheable=true)
    public static Decimal getActivatedOrdersTotalByAccount(Id accountId) {
        if (accountId == null) {
            return 0;
        }

        Map<Id, Decimal> totals = OrderSelector.getTotalsByAccount(
            new Set<Id>{ accountId },
            AccountCAService.ACTIVATED_STATUS
        );
        Decimal total = totals.get(accountId);
        return total != null ? total : 0;
    }
}
