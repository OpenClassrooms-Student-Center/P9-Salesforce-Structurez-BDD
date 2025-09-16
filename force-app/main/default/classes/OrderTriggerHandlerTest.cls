
@isTest(SeeAllData=true)
public class OrderTriggerHandlerTest {
    
    @isTest
    static void testCalculateNetAmount() {
        // 1. Préparer les données
        Account acc = TestDataFactory.createAccount();
      Order ord=  TestDataFactory.createOrder(acc, 'Draft', 50);
         ord = [SELECT Id, TotalAmount, ShipmentCost__c, NetAmount__c FROM Order WHERE Id = :ord.Id];
  

        // 2. Forcer appel de calculateNetAmount
        Test.startTest();
        OrderTriggerHandler.calculateNetAmount(new List<Order>{ord});
        Test.stopTest();

        // 3. Vérification
        System.assertEquals(550, ord.NetAmount__c, 
            'NetAmount doit être TotalAmount (600) - ShipmentCost (50)');
    }
    
@isTest
static void testUpdateAccountCA() {
    // 1. Préparer un compte et une commande en Draft
    Account acc = TestDataFactory.createAccount();
    Order ord = TestDataFactory.createOrder(acc, 'Draft', 0);
    ord = [SELECT Id, AccountId, Status, TotalAmount, ShipmentCost__c, NetAmount__c 
           FROM Order WHERE Id = :ord.Id];

    // 2. Simuler passage de Draft → Activated
    Order oldOrder = ord.clone(false, true, true, true); 
    oldOrder.Status = 'Draft';
    ord.Status = 'Activated';

    // 3. Forcer appel updateAccountCA
    Test.startTest();
    update ord; // permet de recalculer TotalAmount côté Salesforce
    OrderTriggerHandler.updateAccountCA(
        new List<Order>{ord}, 
        new Map<Id, Order>{ord.Id => oldOrder}
    );
    Test.stopTest();

    // 4. Vérification
    acc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals(ord.TotalAmount, acc.Chiffre_d_affaire__c, 
        'Le CA du compte doit être mis à jour avec le TotalAmount de la commande activée');
}



}