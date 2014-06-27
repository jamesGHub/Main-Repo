public interface EventInterface {
     void newEventBatchExecute(List<EventBean> ebList, Service__c serviceObj, Map<Id,System__c> sysMap);
}