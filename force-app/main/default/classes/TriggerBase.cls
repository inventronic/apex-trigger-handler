/**
 * @description     : TriggerBase class to be extended by trigger handlers
 * @author          : Adeel Ahmed
 * @last modified   : 2025-10-04
 */
public abstract class TriggerBase {
  public static final String NOT_IMPLEMENTED = '{0} is not implemented. Consider deactivating from the trigger registry or provide implementation.';
  public static final String EXCEPTION_MESSAGE = 'TriggerBase exception occured.';
  public static final String UNKNOWN_ERROR_MESSAGE = 'Unknown error occurred.';
  public static final String MAX_GENERAL_RECURSIVE_ERROR_MESSAGE = 'The maximum recursive call limit has been reached.';
  public static final String MAX_RECURSIVE_ERROR_MESSAGE = 'The maximum recursive call limit of {0} has been reached in the {1} SObject.';
  public static final String HANDLER_NULL = 'Handler type is not provided.';
  public static final String HANDLER_NOT_VALID = 'Handler type is not valid.';
  public static final String TRIGGER_TYPES_NOT_SAME = 'Unable to run trigger handler due to mismatched SObject types.';
  private static Map<SObjectType, ExecutionCount> states { get; private set; }
  protected final SObjectType sObjType;
  protected TriggerOperation operation { get; private set; }
  private static Boolean dummyTestFlag = false;
  public static Boolean dummyTestCondition {
    get {
      return Test.isRunningTest() ? dummyTestFlag : false;
    }
    set {
      dummyTestFlag = Test.isRunningTest() ? value : false;
    }
  }
  public static void dummyTestErrorOnCondition() {
    if (dummyTestCondition) {
      throw new HandledException('Dummy test exception.');
    }
  }
  public static Set<SObjectType> skippedTriggers { get; private set; }

  public ExecutionCount executionCount {
    get {
      ExecutionCount trgCount = states?.get(this.sObjType);
      return trgCount;
    }
  }

  public List<SObject> newList {
    get {
      return Trigger.new ?? new List<SObject>();
    }
  }
  public List<SObject> oldList {
    get {
      return Trigger.old ?? new List<SObject>();
    }
  }
  public Map<Id, SObject> newMap {
    get {
      return Trigger.newMap ?? new Map<Id, SObject>();
    }
  }
  public Map<Id, SObject> oldMap {
    get {
      return Trigger.oldMap ?? new Map<Id, SObject>();
    }
  }
  @TestVisible
  protected Boolean isBeforeInsert {
    get {
      return this.isActiveBeforeInsert &&
        this.isValid &&
        this.operation == TriggerOperation.BEFORE_INSERT;
    }
  }
  @TestVisible
  protected Boolean isBeforeUpdate {
    get {
      return this.isActiveBeforeUpdate &&
        this.isValid &&
        this.operation == TriggerOperation.BEFORE_UPDATE;
    }
  }
  @TestVisible
  protected Boolean isBeforeDelete {
    get {
      return this.isActiveBeforeDelete &&
        this.isValid &&
        this.operation == TriggerOperation.BEFORE_DELETE;
    }
  }
  @TestVisible
  protected Boolean isAfterInsert {
    get {
      return this.isActiveAfterInsert &&
        this.isValid &&
        this.operation == TriggerOperation.AFTER_INSERT;
    }
  }
  @TestVisible
  protected Boolean isAfterUpdate {
    get {
      return this.isActiveAfterUpdate &&
        this.isValid &&
        this.operation == TriggerOperation.AFTER_UPDATE;
    }
  }
  @TestVisible
  protected Boolean isAfterDelete {
    get {
      return this.isActiveAfterDelete &&
        this.isValid &&
        this.operation == TriggerOperation.AFTER_DELETE;
    }
  }
  @TestVisible
  protected Boolean isAfterUndelete {
    get {
      return this.isActiveAfterUndelete &&
        this.isValid &&
        this.operation == TriggerOperation.AFTER_UNDELETE;
    }
  }
  public String objectName { get; protected set; }
  @TestVisible
  protected Boolean isActive { get; protected set; }
  @TestVisible
  protected Boolean isActiveBeforeInsert { get; protected set; }
  @TestVisible
  protected Boolean isActiveBeforeUpdate { get; protected set; }
  @TestVisible
  protected Boolean isActiveBeforeDelete { get; protected set; }
  @TestVisible
  protected Boolean isActiveAfterInsert { get; protected set; }
  @TestVisible
  protected Boolean isActiveAfterUpdate { get; protected set; }
  @TestVisible
  protected Boolean isActiveAfterDelete { get; protected set; }
  @TestVisible
  protected Boolean isActiveAfterUndelete { get; protected set; }
  @TestVisible
  protected Integer maxExecutionCount { get; protected set; }
  @TestVisible
  protected Boolean isValid {
    get {
      return this.validate();
    }
  }

  static {
    states = new Map<SObjectType, ExecutionCount>();
    skippedTriggers = new Set<SObjectType>();
  }

  {
    try {
      this.operation = Trigger.operationType;
      sObjType = Trigger.isExecuting == true &&
        Trigger.isDelete == true
        ? Trigger.old?.getSObjectType()
        : Trigger.new?.getSObjectType();
      this.objectName = this.sObjType?.getDescribe()?.name ?? 'UnknownSObject';
      loadConfigurations();
    } catch (Exception ex) {
      processError(ex);
      throw getException(ex);
    }
  }

  public TriggerBase(SObjectType handlerSObjType) {
    if (this.sObjType == null && Test.isRunningTest()) {
      this.sObjType = handlerSObjType;
    }
    this.validateSObjects(handlerSObjType);
  }

  @TestVisible
  protected Exception getException() {
    return getException(EXCEPTION_MESSAGE);
  }

  @TestVisible
  protected Exception getExceptionNotImplemented(String message) {
    return getException(
      String.format(NOT_IMPLEMENTED, new List<String>{ message })
    );
  }

  @TestVisible
  protected Exception getException(String message) {
    return new HandledException(message ?? EXCEPTION_MESSAGE);
  }

  @TestVisible
  protected Exception getException(Exception ex) {
    return new HandledException(EXCEPTION_MESSAGE, ex);
  }

  @TestVisible
  protected Exception getException(Exception ex, String message) {
    return new HandledException(message ?? EXCEPTION_MESSAGE, ex);
  }

  public static TriggerBase run(Type handler) {
    TriggerBase baseHandler;
    try {
      if (handler == null) {
        throw new HandledException(HANDLER_NULL);
      }

      if (TriggerBase.class.isAssignableFrom(handler) == false) {
        throw new HandledException(HANDLER_NOT_VALID);
      }

      baseHandler = (TriggerBase) handler.newInstance();
      baseHandler?.runHandler();
    } catch (DmlException ex) {
      processError(ex);
    } catch (Exception ex) {
      processError(ex);
    }
    return baseHandler;
  }

  @TestVisible
  protected virtual void loadConfigurations() {
    this.isActive = false;
    this.isActiveBeforeInsert = false;
    this.isActiveBeforeUpdate = false;
    this.isActiveBeforeDelete = false;
    this.isActiveAfterInsert = false;
    this.isActiveAfterUpdate = false;
    this.isActiveAfterDelete = false;
    this.isActiveAfterUndelete = false;
    try {
      Trigger_Registry__mdt triggerData = Trigger_Registry__mdt.getInstance(
        objectName?.removeEndIgnoreCase('__c')?.trim()
      );

      if (Test.isRunningTest()) {
        triggerData = new Trigger_Registry__mdt();
        triggerData.Active__c = true;
        triggerData.Max_Execution_Count__c = 5;
        triggerData.Before_Insert__c = true;
        triggerData.Before_Update__c = true;
        triggerData.Before_Delete__c = true;
        triggerData.After_Insert__c = true;
        triggerData.After_Update__c = true;
        triggerData.After_Delete__c = true;
        triggerData.After_Undelete__c = true;
        triggerData.DeveloperName = 'Account';
      }

      if (triggerData != null) {
        this.isActive = triggerData.Active__c;
        this.maxExecutionCount = Integer.valueOf(
          triggerData.Max_Execution_Count__c
        );
        this.isActiveBeforeInsert = triggerData.Before_Insert__c;
        this.isActiveBeforeUpdate = triggerData.Before_Update__c;
        this.isActiveBeforeDelete = triggerData.Before_Delete__c;
        this.isActiveAfterInsert = triggerData.After_Insert__c;
        this.isActiveAfterUpdate = triggerData.After_Update__c;
        this.isActiveAfterDelete = triggerData.After_Delete__c;
        this.isActiveAfterUndelete = triggerData.After_Undelete__c;
      }
      dummyTestErrorOnCondition();
    } catch (Exception ex) {
      throw getException(ex);
    }
  }

  protected virtual void runHandler() {
    ExecutionCount trgCount = this.addExecutionCount();
    try {
      this.beforeInsert();
      this.beforeUpdate();
      this.beforeDelete();
      this.afterInsert();
      this.afterUpdate();
      this.afterDelete();
      this.afterUndelete();
    } finally {
      trgCount?.decrease();
    }
  }

  protected ExecutionCount addExecutionCount() {
    ExecutionCount trgCount = TriggerBase.states?.get(this.sObjType);
    if (trgCount == null) {
      trgCount = new ExecutionCount(this.maxExecutionCount);
      TriggerBase.states.put(this.sObjType, trgCount);
    }
    trgCount?.increase();
    return trgCount;
  }

  public virtual Boolean validate() {
    if (this.isActive == false || this.sObjType == null) {
      return false;
    }

    if (skippedTriggers.contains(this.sObjType)) {
      return false;
    }

    ExecutionCount trgCount = states?.get(this.sObjType);
    if (
      (trgCount?.isExceeded == true && Trigger.isExecuting == true) ||
      dummyTestCondition
    ) {
      DepthLimitException ex = new DepthLimitException();
      String message = String.format(
        MAX_RECURSIVE_ERROR_MESSAGE,
        new List<String>{ trgCount?.max?.toString(), objectName }
      );
      ex.setMessage(message);
      processError(ex);
      return false;
    }

    return true;
  }

  @TestVisible
  protected Boolean validateSObjects(SObjectType handlerSObjType) {
    Boolean result =
      this.sObjType != null &&
      handlerSObjType != null &&
      this.sObjType == handlerSObjType;
    if (result == false) {
      throw getException(TRIGGER_TYPES_NOT_SAME);
    }
    return result;
  }

  @TestVisible
  protected virtual void beforeInsert() {
    if (this.isBeforeInsert == false && dummyTestCondition == false) {
      return;
    }

    throw getExceptionNotImplemented('Before Insert');
  }

  @TestVisible
  protected virtual void beforeUpdate() {
    if (this.isBeforeUpdate == false && dummyTestCondition == false) {
      return;
    }

    throw getExceptionNotImplemented('Before Update');
  }

  @TestVisible
  protected virtual void beforeDelete() {
    if (this.isBeforeDelete == false && dummyTestCondition == false) {
      return;
    }

    throw getExceptionNotImplemented('Before Delete');
  }

  @TestVisible
  protected virtual void afterInsert() {
    if (this.isAfterInsert == false && dummyTestCondition == false) {
      return;
    }

    throw getExceptionNotImplemented('After Insert');
  }

  @TestVisible
  protected virtual void afterUpdate() {
    if (this.isAfterUpdate == false && dummyTestCondition == false) {
      return;
    }

    throw getExceptionNotImplemented('After Update');
  }

  @TestVisible
  protected virtual void afterDelete() {
    if (this.isAfterDelete == false && dummyTestCondition == false) {
      return;
    }

    throw getExceptionNotImplemented('After Delete');
  }

  @TestVisible
  protected virtual void afterUndelete() {
    if (this.isAfterUndelete == false && dummyTestCondition == false) {
      return;
    }

    throw getExceptionNotImplemented('After Undelete');
  }

  public static void processError(Exception ex) {
    List<SObject> lstObj = Trigger.new ?? Trigger.old ?? new List<SObject>();
    String errorMessage = ex?.getMessage() ?? UNKNOWN_ERROR_MESSAGE;
    for (SObject eachObj : lstObj) {
      eachObj.addError(errorMessage);
    }
  }

  public static void processError(DmlException ex) {
    List<SObject> lstObj = Trigger.new ?? Trigger.old ?? new List<SObject>();
    String errorMessage = (ex?.getNumDml() > 0
      ? ex?.getDmlMessage(0)
      : ex?.getMessage()) ?? UNKNOWN_ERROR_MESSAGE;
    for (SObject eachObj : lstObj) {
      eachObj.addError(errorMessage);
    }
  }

  public static void processError(DepthLimitException ex) {
    List<SObject> lstObj = Trigger.new ?? Trigger.old ?? new List<SObject>();
    String errorMessage = ex?.getMessage() ??
      MAX_GENERAL_RECURSIVE_ERROR_MESSAGE;
    for (SObject eachObj : lstObj) {
      eachObj.addError(errorMessage);
    }
  }

  public class ExecutionCount {
    private Integer maxCount = 3;
    private Integer currentCount = 0;

    public Integer max {
      get {
        return this.maxCount;
      }
      set {
        this.maxCount = value > 0 && value <= 16 ? value : 5;
      }
    }

    public Integer count {
      get {
        return this.currentCount;
      }
    }

    public Boolean isExceeded {
      get {
        return this.currentCount > this.maxCount;
      }
    }

    public ExecutionCount(Integer maximum) {
      max = maximum;
    }

    public Integer increase() {
      this.currentCount++;
      return this.currentCount;
    }

    public Integer decrease() {
      this.currentCount = this.currentCount != null ? this.currentCount : 0;
      this.currentCount--;
      return this.currentCount;
    }
  }

  public class DepthLimitException extends Exception {
    {
      this.setMessage(MAX_GENERAL_RECURSIVE_ERROR_MESSAGE);
    }
  }
}
