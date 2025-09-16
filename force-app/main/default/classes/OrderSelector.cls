public without sharing class OrderSelector {
// test 
    public static Map<Id, Decimal> getActivatedOrdersSumByAccount(Set<Id> accountIds) {
        Map<Id, Decimal> caMap = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT AccountId accId, SUM(TotalAmount) total
            FROM Order
            WHERE AccountId IN :accountIds AND Status = 'Activated'
            GROUP BY AccountId
        ]) {
            caMap.put((Id) ar.get('accId'), (Decimal) ar.get('total'));
        }
        return caMap;
    }

    @AuraEnabled
    public static Decimal getSumOrdersByAccount(Id accountId) {
        AggregateResult ar = [
            SELECT SUM(TotalAmount) total
            FROM Order
            WHERE AccountId = :accountId AND Status = 'Activated'
        ];
        Decimal total = (Decimal) ar.get('total');
        return total == null ? 0 : total;
    }
    public static Decimal getActivatedOrdersTotalByAccount(Id accountId){
        AggregateResult ar = [
            SELECT SUM(TotalAmount) total
            FROM Order
            WHERE AccountId = :accountId AND Status = 'Activated'
        ];
        return (Decimal) ar.get('total');
    }
    
}
