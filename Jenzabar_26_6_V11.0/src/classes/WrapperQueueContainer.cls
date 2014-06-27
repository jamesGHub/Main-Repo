global with sharing class WrapperQueueContainer{

		public queue__c queueRec;
		public event__c eventRec;
		public topic__c topicRec;
		public Map<String,String> jsonContent = new Map<String,String>();
		public Map<String,ContentMappingHandler.FieldValueDatatypeWrapper> jsonData = new Map<String,ContentMappingHandler.FieldValueDatatypeWrapper>();
		public sObject sObjRec;
		public String objectName;
		public WrapperQueueContainer(Queue__c pQueue,Topic__c pTopic,Event__c pEvent,String pObjectName){
			this.queueRec = pQueue;
			this.topicRec = pTopic;
			this.eventRec = pEvent;
			this.objectName = pObjectName;
		}
}