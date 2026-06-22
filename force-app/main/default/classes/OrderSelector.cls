public with sharing class OrderSelector {

    public static Map<Id, Decimal> getTotalsByAccount(Set<Id> accountIds, String status) {
        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        if (accountIds == null || accountIds.isEmpty()) {
            return totals;
        }
        for (AggregateResult ar : [
            SELECT AccountId, SUM(TotalAmount) total
            FROM Order
            WHERE AccountId IN :accountIds
              AND Status = :status
            GROUP BY AccountId
        ]) {
            Decimal total = (Decimal) ar.get('total');
            totals.put((Id) ar.get('AccountId'), total != null ? total : 0);
        }
        return totals;
    }
}
