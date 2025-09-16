trigger OrderTrigger on Order (before update, after update) {

    if (Trigger.isBefore) {
        OrderTriggerHandler.calculateNetAmount(Trigger.new);
    }

    if (Trigger.isAfter) {
        OrderTriggerHandler.updateAccountCA(Trigger.new, Trigger.oldMap);
    }
}