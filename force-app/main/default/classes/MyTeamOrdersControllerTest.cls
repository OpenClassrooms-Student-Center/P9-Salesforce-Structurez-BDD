/**
 * @description       : Classe de test pour MyTeamOrdersController.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified on  : 05-08-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class MyTeamOrdersControllerTest {

    /**
     * @description : Vérifie le calcul de la somme des commandes "Activated" pour un compte avec commandes.
     */
    @isTest static void testGetSumOrdersByAccount() {
        // Arrange : création d'un compte de test avec la DataFactory
        Account testAccount = TestDataFactory.createAccount('Test Account');

        // Arrange : création de produits actifs avec la DataFactory
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 5; i++) {
            products.add(TestDataFactory.createProduct('Product ' + i));
        }

        // Création des entrées Pricebook pour les produits
        List<PricebookEntry> entries = new List<PricebookEntry>();
        Id pricebookId = Test.getStandardPricebookId();
        for (Product2 p : products) {
            entries.add(TestDataFactory.createPricebookEntry(p, 100.0 + entries.size() * 10));
        }

        // Création des commandes avec statut "Draft"
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 5; i++) {
            orders.add(new Order(
                AccountId = testAccount.Id,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                Pricebook2Id = pricebookId
            ));
        }
        insert orders;

        // Création des OrderItems associés
        List<OrderItem> items = new List<OrderItem>();
        for (Integer i = 0; i < 5; i++) {
            items.add(new OrderItem(
                OrderId = orders[i].Id,
                Quantity = 1,
                UnitPrice = 100 + i * 10,
                PricebookEntryId = entries[i].Id
            ));
        }
        insert items;

        // Activation des commandes
        for (Order o : orders) {
            o.Status = 'Activated';
        }
        update orders;

        // Act : Appel de la méthode et vérification
        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(testAccount.Id);
        Test.stopTest();

        // Assert : Vérification de la somme
        Decimal expected = 100 + 110 + 120 + 130 + 140;
        System.assertEquals(expected, result, 'La somme calculée est incorrecte.');
    }

    /**
     * @description : Vérifie que la méthode retourne 0 si le compte n'a pas de commandes.
     */
    @isTest static void testGetSumOrdersByAccount_NoOrders() {
        // Arrange : création d'un compte sans commande
        Account emptyAccount = TestDataFactory.createAccount('Empty Account');

        // Act : Appel de la méthode et vérification
        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(emptyAccount.Id);
        Test.stopTest();

        // Assert : Vérification que la somme est 0
        System.assertEquals(0, result, 'La somme devrait être 0 pour un compte sans commandes.');
    }

    /**
     * @description : Vérifie qu'une exception est levée si l'ID du compte est null.
     */
    @isTest static void testGetSumOrdersByAccount_InvalidId() {
        // Act & Assert : Vérification que l'exception est levée pour un ID nul
        Test.startTest();
        try {
            MyTeamOrdersController.getSumOrdersByAccount(null);
            System.assert(false, 'Une exception aurait dû être levée pour un ID null.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('L\'ID du compte ne peut pas être nul.', e.getMessage());
        }
        Test.stopTest();
    }
}
