/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class WeeklyProductPriceTest {

    @isTest
    static void testScheduleWeeklyJob() {
        Test.startTest();
        WeeklyProductPriceScheduler.scheduleWeeklyJob();
        Test.stopTest();

        // Vérification via la méthode standard (on ne réutilise pas scheduleJobTest ici volontairement)
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, NextFireTime 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Weekly Product Price Update'
        ];
        System.assertEquals(1, scheduledJobs.size(), 'Le job doit être planifié une fois.');
        System.assertEquals('0 0 0 ? * MON', scheduledJobs[0].CronExpression, 'L\'expression cron doit être correcte.');
        System.assertNotEquals(null, scheduledJobs[0].NextFireTime, 'Le prochain temps d\'exécution ne doit pas être nul.');
    }

    @isTest
    static void testBatchExecution() {
        // Création des données via la factory
        Product2 product = TestDataFactory.createProduct('Test Product');
        PricebookEntry priceEntry = TestDataFactory.createPricebookEntry(product, 100);

        Test.startTest();
        Database.executeBatch(new WeeklyProductPriceUpdater(), 200);
        Test.stopTest();

        // Vérifier que le prix a bien été mis à jour de 10 %
        PricebookEntry updatedEntry = [
            SELECT UnitPrice 
            FROM PricebookEntry 
            WHERE Id = :priceEntry.Id
        ];
        System.assertEquals(110, Integer.valueOf(updatedEntry.UnitPrice),
            'Le prix doit être mis à jour de 10 %.');
    }
}
