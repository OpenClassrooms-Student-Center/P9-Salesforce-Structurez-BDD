@isTest
private class UpdateAllAccountsTest {

    @isTest
    static void batch_recalculatesCAForActivatedAccountsOnly() {
        Account accWithOrders = TestDataFactory.createAccount('Acc With Orders');
        Account accWithoutOrders = TestDataFactory.createAccount('Acc Without Orders');
        Product2 p = TestDataFactory.createProduct('P');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(p.Id, 100);
        Id pbId = Test.getStandardPricebookId();

        Order o = TestDataFactory.createOrder(accWithOrders.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(o.Id, pbe.Id, 2, 100);
        o.Status = TestDataFactory.STATUS_ACTIVATED;
        update o;

        // Simule une corruption manuelle du CA, que le batch doit corriger.
        accWithOrders.Chiffre_d_affaire__c = 99999;
        update accWithOrders;

        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts(), 200);
        Test.stopTest();

        Account refreshedWith = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accWithOrders.Id];
        System.assertEquals(200, refreshedWith.Chiffre_d_affaire__c,
            'Le batch doit recalculer le CA a partir des Orders Activated');

        Account refreshedWithout = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accWithoutOrders.Id];
        System.assertEquals(null, refreshedWithout.Chiffre_d_affaire__c,
            'Le compte sans commande Activated n\'est pas dans le scope du batch (filtre start())');
    }

    @isTest
    static void batch_bulkMultipleAccounts_recalculatesAll() {
        Product2 p = TestDataFactory.createProduct('P');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(p.Id, 100);
        Id pbId = Test.getStandardPricebookId();

        List<Account> accounts = TestDataFactory.createAccounts(10);
        for (Account a : accounts) {
            Order o = TestDataFactory.createOrder(a.Id, pbId, TestDataFactory.STATUS_DRAFT);
            TestDataFactory.createOrderItem(o.Id, pbe.Id, 1, 100);
            o.Status = TestDataFactory.STATUS_ACTIVATED;
            update o;
        }

        // Corruption volontaire des CA
        for (Account a : accounts) {
            a.Chiffre_d_affaire__c = 0;
        }
        update accounts;

        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts(), 200);
        Test.stopTest();

        List<Account> refreshed = [
            SELECT Chiffre_d_affaire__c
            FROM Account
            WHERE Id IN :new Map<Id, Account>(accounts).keySet()
        ];
        for (Account a : refreshed) {
            System.assertEquals(100, a.Chiffre_d_affaire__c,
                'Chaque compte doit avoir un CA recalcule a 100');
        }
    }
}
