/**
 * @description     : AccountTrigger to handle Account triggers
 * @author          : Adeel Ahmed
 * @last modified   : 2025-10-03
 */
trigger AccountTrigger on Account(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerBase.run(AccountTriggerHandler.class);
}
