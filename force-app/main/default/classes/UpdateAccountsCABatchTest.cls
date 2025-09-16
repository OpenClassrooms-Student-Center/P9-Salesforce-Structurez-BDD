@isTest(SeeAllData=true)
public class UpdateAccountsCABatchTest {

    @isTest
    static void testBatchExecution() {
        // 1. Préparer données
        Account acc = TestDataFactory.createAccount();
        Order ord = TestDataFactory.createOrder(acc, 'Draft', 0);
        ord.Status = 'Activated';
        update ord;

     

        // 2. Exécuter le batch
        Test.startTest();
        UpdateAccountsCABatch batch = new UpdateAccountsCABatch();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        // 3. Vérifier que le CA du compte correspond bien
        acc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(ord.TotalAmount, acc.Chiffre_d_affaire__c,
            'Le batch doit garantir que le CA est correctement mis à jour');
    }
}
