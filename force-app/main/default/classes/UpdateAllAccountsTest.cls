/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class UpdateAllAccountsTest {

    /**
     * Test de l'exécution du batch UpdateAllAccounts
     * Vérifie la mise à jour correcte du champ ChiffreAffaire__c sur les comptes liés à des commandes "Activated"
     */
    @isTest
    static void testUpdateAllAccountsBatchExecution() {
        // Création de deux comptes
        List<Account> accounts = TestDataFactory.createMultipleAccounts(2);
        Account acc1 = accounts[0];
        Account acc2 = accounts[1];

        // Création d'un produit et d'une entrée Pricebook
        Product2 product = TestDataFactory.createProduct('Test Product');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, 100);

        // Création de commandes en statut "Draft" pour les comptes
        List<Order> orders = new List<Order>{
            new Order(AccountId = acc1.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = pbe.Pricebook2Id),
            new Order(AccountId = acc2.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = pbe.Pricebook2Id),
            new Order(AccountId = acc1.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = pbe.Pricebook2Id),
            new Order(AccountId = acc2.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = pbe.Pricebook2Id),
            new Order(AccountId = acc1.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = pbe.Pricebook2Id)
        };
        insert orders;

        // Ajout d'OrderItems avec quantités et prix unitaires personnalisés
        List<OrderItem> items = new List<OrderItem>{
            new OrderItem(OrderId = orders[0].Id, PricebookEntryId = pbe.Id, Quantity = 2, UnitPrice = 150),
            new OrderItem(OrderId = orders[1].Id, PricebookEntryId = pbe.Id, Quantity = 3, UnitPrice = 200),
            new OrderItem(OrderId = orders[2].Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100),
            new OrderItem(OrderId = orders[3].Id, PricebookEntryId = pbe.Id, Quantity = 4, UnitPrice = 50),
            new OrderItem(OrderId = orders[4].Id, PricebookEntryId = pbe.Id, Quantity = 5, UnitPrice = 25)
        };
        insert items;

        // Activation des commandes (changement du statut en 'Activated')
        for (Order ord : orders) {
            ord.Status = 'Activated';
        }
        update orders;

        // Exécution du batch pour mettre à jour les comptes
        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts(), 200);
        Test.stopTest();

        // Récupération des comptes mis à jour
        Account updatedAcc1 = [SELECT ChiffredAffaire__c FROM Account WHERE Id = :acc1.Id];
        Account updatedAcc2 = [SELECT ChiffredAffaire__c FROM Account WHERE Id = :acc2.Id];

        // Calcul attendu du chiffre d'affaires par compte
        Decimal expected1 = (2 * 150) + (1 * 100) + (5 * 25); // 300 + 100 + 125 = 525
        Decimal expected2 = (3 * 200) + (4 * 50);             // 600 + 200 = 800

        // Vérification que les valeurs correspondent aux montants attendus
        System.assertEquals(expected1, updatedAcc1.ChiffredAffaire__c, 'Chiffre d’affaires incorrect pour acc1');
        System.assertEquals(expected2, updatedAcc2.ChiffredAffaire__c, 'Chiffre d’affaires incorrect pour acc2');
    }

    /**
     * Test de la planification du batch via la classe UpdateAllAccountsScheduler
     */
    @isTest
    static void testSchedulerSetup() {
        Test.startTest();
        String jobId = System.schedule('Test UpdateAllAccountsScheduler', '0 0 0 ? * SUN', new UpdateAllAccountsScheduler());
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, CronExpression 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Test UpdateAllAccountsScheduler'
        ];
        System.assertEquals(1, jobs.size(), 'Le job planifié n’a pas été créé');
        System.assertEquals('0 0 0 ? * SUN', jobs[0].CronExpression, 'L’expression CRON est incorrecte');
    }
}
