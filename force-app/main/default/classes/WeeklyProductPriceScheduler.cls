/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class WeeklyProductPriceScheduler implements Schedulable {

    // Méthode de planification du job qui déclenche le batch
    global void execute(SchedulableContext sc) {
        // Exécution du batch avec un scope size de 200 (par défaut)
        WeeklyProductPriceUpdater batch = new WeeklyProductPriceUpdater();
        Database.executeBatch(batch, 200);
    }
    // Méthode pour planifier le job chaque lundi à minuits = scope;        
    public static void scheduleWeeklyJob() {
        // Planification du job : chaque lundi à 00:00
        String cronExp = '0 0 0 ? * MON';  // Cron : chaque lundi à minuit
        System.schedule('Weekly Product Price Update', cronExp, new WeeklyProductPriceScheduler());
    }
}

