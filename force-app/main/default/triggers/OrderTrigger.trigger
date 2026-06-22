trigger OrderTrigger on Order (after insert, after update, after delete, after undelete) {
    OrderTriggerHandler.run();
}
