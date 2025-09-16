@isTest(SeeAllData=true)
public class OrderSelectorTest {

    @isTest
    static void testGetActivatedOrdersSumByAccount() {
        // 1. Préparer données
        Account acc = TestDataFactory.createAccount();
        Order ord = TestDataFactory.createOrder(acc, 'Draft', 0);
        // Activer l’ordre
        ord.Status = 'Activated';
        update ord;
        // 2. Exécuter la méthode
        Test.startTest();
        Map<Id, Decimal> result = OrderSelector.getActivatedOrdersSumByAccount(new Set<Id>{acc.Id});
        Test.stopTest();

        // 3. Vérification
        System.assertEquals(true, result.containsKey(acc.Id), 'Le compte doit être présent dans le résultat');
        System.assertEquals(ord.TotalAmount, result.get(acc.Id), 'La somme des commandes activées doit correspondre au TotalAmount');
    }

    @isTest
    static void testGetSumOrdersByAccount() {
        // 1. Préparer données
        Account acc = TestDataFactory.createAccount();
        Order ord = TestDataFactory.createOrder(acc, 'Draft', 0);
        ord.Status = 'Activated';
        update ord;

        // 2. Exécuter la méthode
        Test.startTest();
        Decimal total = OrderSelector.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        // 3. Vérification
        System.assertEquals(ord.TotalAmount, total, 'La somme doit correspondre au TotalAmount de la commande activée');
    }

    @isTest
    static void testGetActivatedOrdersTotalByAccount() {
        // 1. Préparer données
        Account acc = TestDataFactory.createAccount();
        Order ord = TestDataFactory.createOrder(acc, 'Draft', 0);
        ord.Status = 'Activated';
        update ord;

        // 2. Exécuter la méthode
        Test.startTest();
        Decimal total = OrderSelector.getActivatedOrdersTotalByAccount(acc.Id);
        Test.stopTest();

        // 3. Vérification
        System.assertEquals(ord.TotalAmount, total, 'Le total doit correspondre au TotalAmount de la commande activée');
    }
}
