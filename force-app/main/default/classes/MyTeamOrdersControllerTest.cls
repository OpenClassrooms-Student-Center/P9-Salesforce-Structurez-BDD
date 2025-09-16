@isTest(SeeAllData=true)
public class MyTeamOrdersControllerTest {
    
    @isTest
    static void testGetSumOrdersByAccount() {
        // 1. Préparer un compte
        Account acc = TestDataFactory.createAccount();

        // 2. Créer une commande avec des OrderItems
        Order ord = TestDataFactory.createOrder(acc, 'Draft', 50);
        ord.Status = 'Activated'; 
        update ord;

        // Vérifier que TotalAmount est bien calculé
        ord = [SELECT Id, TotalAmount FROM Order WHERE Id = :ord.Id];
        System.debug('TotalAmount = ' + ord.TotalAmount);

        // 3. Appeler le contrôleur
        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        // 4. Vérification (TotalAmount 600 - shipmentCost 50 ne compte pas ici,
        // car OrderService.getAccountCA retourne juste la somme des TotalAmount)
        System.assertEquals(600, result, 
            'Le total retourné doit être égal au TotalAmount de la commande activée');
    }
    // test 4
}

