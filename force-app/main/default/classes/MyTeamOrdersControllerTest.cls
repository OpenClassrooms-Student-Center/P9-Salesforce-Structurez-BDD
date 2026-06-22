@isTest
private class MyTeamOrdersControllerTest {

    @isTest
    static void getActivatedOrdersTotalByAccount_nullAccountId_returnsZero() {
        Test.startTest();
        Decimal result = MyTeamOrdersController.getActivatedOrdersTotalByAccount(null);
        Test.stopTest();
        System.assertEquals(0, result, 'Doit retourner 0 si accountId est null');
    }

    @isTest
    static void getActivatedOrdersTotalByAccount_returnsSum() {
        Account acc = TestDataFactory.createAccount('Acc');
        Product2 p = TestDataFactory.createProduct('P');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(p.Id, 100);
        Id pbId = Test.getStandardPricebookId();

        Order o = TestDataFactory.createOrder(acc.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(o.Id, pbe.Id, 3, 100);
        o.Status = TestDataFactory.STATUS_ACTIVATED;
        update o;

        Test.startTest();
        Decimal result = MyTeamOrdersController.getActivatedOrdersTotalByAccount(acc.Id);
        Test.stopTest();

        System.assertEquals(300, result, 'Doit retourner la somme des commandes Activated');
    }

    @isTest
    static void getActivatedOrdersTotalByAccount_noActivatedOrder_returnsZero() {
        Account acc = TestDataFactory.createAccount('Acc');
        Product2 p = TestDataFactory.createProduct('P');
        PricebookEntry pbe = TestDataFactory.createStandardPricebookEntry(p.Id, 100);
        Id pbId = Test.getStandardPricebookId();

        Order o = TestDataFactory.createOrder(acc.Id, pbId, TestDataFactory.STATUS_DRAFT);
        TestDataFactory.createOrderItem(o.Id, pbe.Id, 3, 100);

        Test.startTest();
        Decimal result = MyTeamOrdersController.getActivatedOrdersTotalByAccount(acc.Id);
        Test.stopTest();

        System.assertEquals(0, result, 'Doit retourner 0 sans commande Activated');
    }
}
