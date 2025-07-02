/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class CalculMontantTest {

    @isTest
    static void test_NetAmountCalculation_WithShipmentCost() {
        // Données de test via la factory
        Account acc = TestDataFactory.createAccount('Compte Test');
        Product2 prod = TestDataFactory.createProduct('Produit Test');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, 300);

        // Création de la commande (avec TotalAmount via OrderItem)
        Order order = TestDataFactory.createOrder(acc, pbe);

        // Mise à jour avec un coût de livraison pour déclencher le calcul du NetAmount__c
        order.ShipmentCost__c = 50;

        Test.startTest();
        update order; // Déclenche le trigger CalculMontant
        Test.stopTest();

        // Validation du calcul
        Order result = [SELECT TotalAmount, ShipmentCost__c, NetAmount__c FROM Order WHERE Id = :order.Id];
        System.assertEquals(300, result.TotalAmount, 'Le montant total devrait être 300');
        System.assertEquals(50, result.ShipmentCost__c, 'Le coût d’expédition devrait être 50');
        System.assertEquals(250, result.NetAmount__c, 'Le montant net devrait être 300 - 50 = 250');
    }

    @isTest
    static void test_NetAmountCalculation_NullShipmentCost() {
        Account acc = TestDataFactory.createAccount('Compte Sans Livraison');
        Product2 prod = TestDataFactory.createProduct('Produit Simple');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod, 100);

        Order order = TestDataFactory.createOrder(acc, pbe);
        // Ne pas définir ShipmentCost__c (il reste null)

        Test.startTest();
        update order;
        Test.stopTest();

        Order result = [SELECT TotalAmount, ShipmentCost__c, NetAmount__c FROM Order WHERE Id = :order.Id];
        System.assertEquals(100, result.TotalAmount, 'TotalAmount doit être 100');
        System.assertEquals(null, result.ShipmentCost__c, 'ShipmentCost__c doit être null');
        System.assertEquals(100, result.NetAmount__c, 'NetAmount__c doit rester égal à TotalAmount si ShipmentCost est null');
    }
}
