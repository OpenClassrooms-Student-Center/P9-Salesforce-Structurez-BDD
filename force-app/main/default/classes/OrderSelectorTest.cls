@isTest
private class OrderSelectorTest {

    @isTest
    static void getTotalsByAccount_nullSet_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Decimal> result = OrderSelector.getTotalsByAccount(
            null, TestDataFactory.STATUS_ACTIVATED
        );
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Map vide attendue pour un Set null');
    }

    @isTest
    static void getTotalsByAccount_emptySet_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Decimal> result = OrderSelector.getTotalsByAccount(
            new Set<Id>(), TestDataFactory.STATUS_ACTIVATED
        );
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Map vide attendue pour un Set vide');
    }

    @isTest
    static void getTotalsByAccount_filtersByStatusAndSums() {
        Account acc = TestDataFactory.createAccount('Acc');
        Product2 p = TestDataFactory.createProduct('P');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(p.Id, 100);
        Id pbId = Test.getStandardPricebookId();

        Order o1 = TestDataFactory.createOrder(acc.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(o1.Id, pbe.Id, 1, 100);
        o1.Status = TestDataFactory.STATUS_ACTIVATED;
        update o1;

        Order o2 = TestDataFactory.createOrder(acc.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(o2.Id, pbe.Id, 2, 100);
        o2.Status = TestDataFactory.STATUS_ACTIVATED;
        update o2;

        Test.startTest();
        Map<Id, Decimal> result = OrderSelector.getTotalsByAccount(
            new Set<Id>{ acc.Id }, TestDataFactory.STATUS_ACTIVATED
        );
        Test.stopTest();

        System.assertEquals(300, result.get(acc.Id),
            'Somme des deux Orders Activated attendue (100 + 200)');
    }

    @isTest
    static void getTotalsByAccount_otherStatus_returnsNothing() {
        Account acc = TestDataFactory.createAccount('Acc');
        Product2 p = TestDataFactory.createProduct('P');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(p.Id, 100);
        Id pbId = Test.getStandardPricebookId();

        Order o = TestDataFactory.createOrder(acc.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(o.Id, pbe.Id, 1, 100);

        Test.startTest();
        Map<Id, Decimal> result = OrderSelector.getTotalsByAccount(
            new Set<Id>{ acc.Id }, TestDataFactory.STATUS_ACTIVATED
        );
        Test.stopTest();

        System.assert(!result.containsKey(acc.Id) || result.get(acc.Id) == 0,
            'Aucune commande Activated, total attendu absent ou nul');
    }
}
