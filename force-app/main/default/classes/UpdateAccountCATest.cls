/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class UpdateAccountCATest {

    /**
     * @description : Teste le déclencheur UpdateAccountCA pour s'assurer que le chiffre d'affaire du compte est mis à jour
     * lors du passage du statut de la commande à "Activated".
     */
    @isTest
    static void testUpdateAccountCA() {
        // Arrange : Création des données nécessaires via TestDataFactory
        Account acc = TestDataFactory.createAccount('Compte Test');
        Product2 prod = TestDataFactory.createProduct('Produit Test');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, 1500.00);

        // Création d'une commande de test avec l'account et pricebookEntry
        Order ord = TestDataFactory.createOrder(acc, pbe);

        // Mise à jour du statut de la commande à "Activated"
        ord.Status = 'Activated';

        Test.startTest();
        update ord; // Le déclencheur UpdateAccountCA se déclenchera ici
        Test.stopTest();

        // Vérification que le chiffre d'affaire du compte est mis à jour correctement
        acc = [SELECT ChiffredAffaire__c FROM Account WHERE Id = :acc.Id];

        // Affichage de la valeur du chiffre d'affaires pour diagnostiquer
        System.debug('Chiffre d\'affaire du compte après activation de la commande : ' + acc.ChiffredAffaire__c);

        // Assertion : Le chiffre d'affaires du compte doit être égal à 1500 €
        System.assertEquals(1500.00, acc.ChiffredAffaire__c, 'Le chiffre d\'affaire du compte doit être égal à 1500 €.');
    }

    /**
     * @description : Teste le cas où plusieurs commandes sont activées pour le même compte.
     */
    @isTest
    static void testUpdateAccountCA_MultipleOrders() {
        // Arrange
        Account acc = TestDataFactory.createAccount('Compte Test Multiple');
        Product2 prod = TestDataFactory.createProduct('Produit Test Multiple');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, 1500.00);
    
        // Création manuelle de deux commandes pour le même compte
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 2; i++) {
            Order order = new Order(
                AccountId = acc.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = pbe.Pricebook2Id
            );
            orders.add(order);
        }
        insert orders;
    
        // Ajout de OrderItems pour chaque commande
        List<OrderItem> items = new List<OrderItem>();
        for (Order ord : orders) {
            items.add(new OrderItem(
                OrderId = ord.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = pbe.UnitPrice
            ));
        }
        insert items;
    
        // Activation des commandes
        for (Order ord : orders) {
            ord.Status = 'Activated';
        }
    
        Test.startTest();
        update orders;
        Test.stopTest();
    
        // Vérification du CA
        acc = [SELECT ChiffredAffaire__c FROM Account WHERE Id = :acc.Id];
        System.debug('Chiffre d\'affaire du compte après activation des commandes : ' + acc.ChiffredAffaire__c);
        System.assertEquals(3000.00, acc.ChiffredAffaire__c, 'Le chiffre d\'affaire du compte doit être égal à 3000 €.');
    }
}
