/**
 * @description     : AccountTriggerHandler drived from TriggerBase to handle Account triggers
 * @author          : Adeel Ahmed
 * @last modified   : 2025-10-03
 */
public with sharing class AccountTriggerHandler extends TriggerBase {
  public AccountTriggerHandler() {
    super(Account.SObjectType);
  }

  protected override void beforeInsert() {
    if (this.isBeforeInsert == false) {
      return;
    }

    for (Account acc : (List<Account>) this.newList) {
      acc.Name = acc.Name + ' added';
    }
  }

  protected override void beforeUpdate() {
    if (this.isBeforeUpdate == false) {
      return;
    }

    for (Account acc : (List<Account>) this.newList) {
      acc.Name = acc.Name + ' Updated';
    }
  }

  protected override void afterInsert() {
    if (this.isAfterInsert == false) {
      return;
    }

    Account a = new Account();
    a.Name = 'New Account Aft Ins ' + this.executionCount.count.toString();
    a.Father_s_Email__c = 'a@a.com';
    insert a;
  }

  protected override void afterUpdate() {
    if (this.isAfterUpdate == false) {
      return;
    }

    Account a = new Account();
    a.Name = 'New Account Aft Upd ' + this.executionCount.count.toString();
    a.Father_s_Email__c = 'a@a.com';
    insert a;
  }
}
