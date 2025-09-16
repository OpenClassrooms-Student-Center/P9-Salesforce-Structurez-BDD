@isTest(SeeAllData=true)
public class OrderServiceTest {

    @isTest
    static void testGetAccountCA() {
        // 1. Préparer les données
        Account acc = TestDataFactory.createAccount();
        Order ord = TestDataFactory.createOrder(acc, 'Draft', 0);
        ord.Status = 'Activated';
        update ord;

        // 2. Exécuter la méthode
        Test.startTest();
        Decimal ca = OrderService.getAccountCA(acc.Id);
        Test.stopTest();

        // 3. Vérification
        System.assertEquals(600, ca,
            'Le CA du compte doit être égal à la somme des OrderItems (600)');
    }
     @IsTest
    static void testUpdateAccountsCA() {
        // 1. Créer un compte
        Account acc = TestDataFactory.createAccount();

        // 2. Créer des commandes en Draft
        List<Order> orders = new List<Order>();
        for(Integer i = 0; i < 3; i++) {
            orders.add(TestDataFactory.createOrder(acc, 'Draft', 50));
        }

        // 3. Passer les commandes en Activated
        List<Order> activatedOrders = new List<Order>();
        for(Order o : orders) {
            o.Status = 'Activated';
            activatedOrders.add(o);
        }
        update activatedOrders;

        // 4. Préparer le set d'Id de comptes
        Set<Id> accountIds = new Set<Id>{acc.Id};

        // 5. Appeler la méthode à tester
        Test.startTest();
        OrderService.updateAccountsCA(accountIds);
        Test.stopTest();

        // 6. Vérifier le chiffre d'affaires
        acc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        Decimal expectedCA = 0;
        for(Order o : [SELECT TotalAmount FROM Order WHERE AccountId = :acc.Id AND Status = 'Activated']) {
            expectedCA += o.TotalAmount;
        }

        System.assertEquals(expectedCA, acc.Chiffre_d_affaire__c, 
            'Le CA du compte doit correspondre à la somme des TotalAmount des commandes activées');
    }
}
