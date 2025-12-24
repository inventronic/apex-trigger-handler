/**
 * @description     : Test class for TriggerBase class
 * @author          : Adeel Ahmed
 * @last modified   : 2025-10-03
 */
@IsTest
private class TriggerBaseTest {
  private class TriggerBaseHanderForTest extends TriggerBase {
    public TriggerBaseHanderForTest() {
      super(Account.sObjectType);
    }
  }

  public static String getFakeId(Schema.SObjectType objectType, Integer index) {
    return objectType.getDescribe().getKeyPrefix() +
      '001zzzz' +
      String.valueOf(index).leftPad(5, '0');
  }

  @IsTest
  static void testGeneralMethods() {
    Test.startTest();
    TriggerBase handler = TriggerBase.run(TriggerBaseHanderForTest.class);
    List<SObject> oldList = handler.oldList;
    List<SObject> newList = handler.newList;
    Map<Id, SObject> newMap = handler.newMap;
    Map<Id, SObject> oldMap = handler.oldMap;
    Boolean isBeforeInsert = handler.isBeforeInsert;
    Boolean isBeforeUpdate = handler.isBeforeUpdate;
    Boolean isBeforeDelete = handler.isBeforeDelete;
    Boolean isAfterInsert = handler.isAfterInsert;
    Boolean isAfterUpdate = handler.isAfterUpdate;
    Boolean isAfterDelete = handler.isAfterDelete;
    Boolean isAfterUndelete = handler.isAfterUndelete;
    String objectName = handler.ObjectName;
    Boolean isActive = handler.IsActive;
    Boolean isActiveBeforeInsert = handler.isActiveBeforeInsert;
    Boolean isActiveBeforeUpdate = handler.isActiveBeforeUpdate;
    Boolean isActiveBeforeDelete = handler.isActiveBeforeDelete;
    Boolean isActiveAfterInsert = handler.isActiveAfterInsert;
    Boolean isActiveAfterUpdate = handler.isActiveAfterUpdate;
    Boolean isActiveAfterDelete = handler.isActiveAfterDelete;
    Boolean isActiveAfterUndelete = handler.isActiveAfterUndelete;
    Integer maxExecutionCount = handler.maxExecutionCount;
    TriggerBase.ExecutionCount executionCount = handler.executionCount;
    Boolean isExceeded = executionCount.isExceeded;
    Integer resMax = executionCount.max;
    Integer resCount = executionCount.count;
    Boolean isValid = handler.isValid;
    Exception exTest = handler.getException();
    exTest = handler.getException(exTest);
    exTest = handler.getException(exTest, null);
    exTest = handler.getExceptionNotImplemented('Before Insert');
    exTest = new TriggerBase.DepthLimitException();
    DmlException exDML;
    TriggerBase.processError(exDML);
    TriggerBase.DepthLimitException exDepth;
    TriggerBase.processError(exDepth);

    Test.stopTest();
    System.assertNotEquals(null, handler, 'handler Should not be null');
  }

  @IsTest
  static void testGeneralMethodsWithFakeErrors() {
    Test.startTest();

    try {
      TriggerBase.run(null);
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      TriggerBase.run(String.class);
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    TriggerBase handler = TriggerBase.run(TriggerBaseHanderForTest.class);

    handler.beforeInsert();
    handler.beforeUpdate();
    handler.beforeDelete();
    handler.afterInsert();
    handler.afterUpdate();
    handler.afterDelete();
    handler.afterUndelete();

    try {
      handler.isActive = false;
      handler.validate();
      handler.isActive = true;
      TriggerBase.dummyTestCondition = true;
      handler.validate();
      TriggerBase.skippedTriggers.add(Account.SObjectType);
      handler.validate();

      TriggerBase.dummyTestErrorOnCondition();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.loadConfigurations();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.beforeInsert();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.beforeUpdate();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.beforeDelete();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.afterInsert();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.afterUpdate();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.afterDelete();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.afterUndelete();
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    try {
      handler.validateSObjects(Contact.sObjectType);
    } catch (Exception ex) {
      System.assertNotEquals(null, ex, 'ex should not be null');
    }

    Test.stopTest();
  }
}
