@isTest
private class AccountCAServiceTest {

    @isTest
    static void recalculateForAccounts_nullSet_doesNothing() {
        Test.startTest();
        AccountCAService.recalculateForAccounts(null);
        Test.stopTest();
        System.assert(true, 'Aucune exception attendue avec un Set null');
    }

    @isTest
    static void recalculateForAccounts_emptySet_doesNothing() {
        Test.startTest();
        AccountCAService.recalculateForAccounts(new Set<Id>());
        Test.stopTest();
        System.assert(true, 'Aucune exception attendue avec un Set vide');
    }

    @isTest
    static void recalculateForAccounts_sumsOnlyActivatedOrders() {
        Account acc = TestDataFactory.createAccount('Acc Mix');
        Product2 p = TestDataFactory.createProduct('P');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(p.Id, 100);
        Id pbId = Test.getStandardPricebookId();

        Order activated = TestDataFactory.createOrder(acc.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(activated.Id, pbe.Id, 2, 100);
        activated.Status = TestDataFactory.STATUS_ACTIVATED;
        update activated;

        Order draft = TestDataFactory.createOrder(acc.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(draft.Id, pbe.Id, 3, 100);

        Test.startTest();
        AccountCAService.recalculateForAccounts(new Set<Id>{ acc.Id });
        Test.stopTest();

        Account refreshed = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(200, refreshed.Chiffre_d_affaire__c,
            'Seules les commandes Activated doivent etre sommees');
    }

    @isTest
    static void recalculateForAccounts_noActivatedOrder_setsZero() {
        Account acc = TestDataFactory.createAccount('Acc Zero');
        Product2 p = TestDataFactory.createProduct('P');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(p.Id, 100);
        Id pbId = Test.getStandardPricebookId();

        Order o = TestDataFactory.createOrder(acc.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(o.Id, pbe.Id, 5, 100);

        Test.startTest();
        AccountCAService.recalculateForAccounts(new Set<Id>{ acc.Id });
        Test.stopTest();

        Account refreshed = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, refreshed.Chiffre_d_affaire__c,
            'CA doit etre 0 si aucune commande Activated');
    }
}
