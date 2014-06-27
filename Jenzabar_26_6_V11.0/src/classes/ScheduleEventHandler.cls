public with sharing class ScheduleEventHandler  {
    private static final String TYPE = 'Type';
    private static final String LOCATION = 'Location';
    
    /**
     * Method to fetch all new events and group them by retriever type.
     * Based on retriever type it will call batch class and pass list of EventBean and Map of System.
     * EventBean is a wrapper class consists of Event object and parsed Retriever type and Retriever Link.
     */
    public static void fetchNewEvent(){
          set<ID> sourceSystemIds = new Set<ID>(); 
          List<EventBean> eventBeanList = new List<EventBean>();          
          List<Event__c> newEventList = [Select id,
                                                Event_State_ID__c,
                                                Topic_ID__c ,
                                                Retriever_Info__c,
                                                SourceSystem_ID__c,
                                                Content_JSON__c
                                                FROM Event__c 
                                                WHERE Event_State_ID__c =: Label.Event_New];

          for(Event__c eventInst : newEventList){
                sourceSystemIds.add(eventInst.SourceSystem_ID__c);
          }
          Map<Id,System__c> systemMap = new Map<Id,System__c>([Select id,
																	  Name,
																	  (Select LocalObject__c,JSONObject__c,Local_Field__c,JSONField__c FROM Content_Mappings__r),
			                                                          (Select Id, Name, System__c, Service__c, Service__r.Name, URL__c, Credentials__c, Token__c, Subscriber__c From Credentials__r)															
																	  from System__c where id IN : sourceSystemIds]);
																	  
		  List<Service__c> serviceList = [select id,Name,	Class__c,Transaction_Scope__c from Service__c];
		  													  
	      Map<String,Service__c> serviceMap = new Map<String,Service__c>();
	      for(Service__c sInst : serviceList){
	      	    serviceMap.put(sInst.Name,sInst);
	      }
	      																                                                         
          for(Event__c eInst : newEventList){
                if(eInst.Content_JSON__c == null || eInst.Content_JSON__c == ''){
	                String rtype,rlink;
	                EventBean eventBeanObj = new EventBean();
	                Map<String, String> InfoRetrievalMap = retrieverMap(eInst.Retriever_Info__c);//Parsing retreval info JSON content
	                if(InfoRetrievalMap != null && !InfoRetrievalMap.isEmpty()){
	                     System__c systemObj = systemMap.get(Id.ValueOf(eInst.SourceSystem_ID__c));
	                     if(systemObj != null){
	                         for(Content_Mapping__c contentMapInst : systemObj.Content_Mappings__r){
	                              if(contentMapInst.Local_Field__c.equalsIgnoreCase(TYPE)){
	                                    rtype = InfoRetrievalMap.get(contentMapInst.JSONField__c);
	                              }
	                              else if(contentMapInst.Local_Field__c.equalsIgnoreCase(LOCATION)){
	                                    rlink = InfoRetrievalMap.get(contentMapInst.JSONField__c);
	                              }
	                         }
	                         eventBeanObj.eventObj = eInst;
	                         eventBeanObj.retriverType = rtype;
	                         eventBeanObj.link = rlink;
	                         eventBeanList.add(eventBeanObj);
	                     }
	                }
                }
          } 
          Map<String, List<EventBean>> retriverTypeEventMap = new Map<String, List<EventBean>>();
          for(EventBean beanInst : eventBeanList){
                if(retriverTypeEventMap != null && retriverTypeEventMap.containsKey(beanInst.retriverType)){
                      retriverTypeEventMap.get(beanInst.retriverType).add(beanInst);
                }
                else{
                     retriverTypeEventMap.put(beanInst.retriverType,new EventBean[]{beanInst}); 
                }
          }
          
          for(String rType : retriverTypeEventMap.keySet()){
          	    if(serviceMap != null){
          	    	Service__c serviceObj = serviceMap.get(rType);
          	    	if(serviceObj != null && serviceObj.Class__c != null && serviceObj.Class__c != ''){
		                System.Type typeObj = System.Type.forName(serviceObj.Class__c);
		                if(typeObj != null){
		                	Object obj = typeObj.newInstance();
		                    EventInterface eInterface = (EventInterface)obj;
		                    if(eInterface != null){
		                    	//Pass serice object to retriver to set batch scope and handle when a system is linked with multiple services
		                        eInterface.newEventBatchExecute(retriverTypeEventMap.get(rType),serviceObj,systemMap); 
		                    }
		                }
          	    	}
          	    }
          }
    }        
    /**
     * Method to fetch list of ready events and group them by TopicId.
     * Based on TopicId, it will call queuer and pass list of ready event.
     */ 
    @future
    public static void createReadyQueue(){
        Map<Id,Event__c> eventMapToUpdate = new Map<Id,Event__c>();
        Map<id,List<Event__c>> eventMap = new Map<Id,List<Event__c>>();
        List<Event__c> eventLsttoUpdate = new List<Event__c>();
        for(Event__c eventItr : [SELECT Id,
                                        Event_State_ID__c,
                                        Topic_ID__c ,
                                        Retriever_Info__c,
                                        Content_JSON__c,
                                        SourceSystem_ID__c
                                        FROM Event__c
                                        WHERE Event_State_ID__c =: Label.Event_Ready
                                       ]){
       
            if(!String.isEmpty(eventItr.Content_JSON__c)){
                    if(eventMap.containsKey(eventItr.Topic_ID__c)){
                        eventMap.get(eventItr.Topic_ID__c).add(eventItr);
                    }
                    else{
                        eventMap.put(eventItr.Topic_ID__c,new List<Event__c>{eventItr});
                    }
             }
             eventItr.Event_State_ID__c = 'In Progress';
             eventLsttoUpdate.add(eventItr);
         }
         CreateQueue.createQueuewithHandler(eventMap);
         if(!eventLsttoUpdate.isEmpty()){
            System.debug('eventLsttoUpdate==='+eventLsttoUpdate);
            Database.saveResult[] result = Database.update(eventLsttoUpdate);
            System.debug('result==='+result);
         }
         
    }
    /**
     * Method to parse JSON content available in retrieverInfo field of event record.
     * Argument: RetrieverInfo field value.
     * Return: Map of field name and field value of JSON content.
     */
    private static Map<String, String> retrieverMap(String retInfo){
        String retrieverInfo = '\''+retInfo+'\'';
        Map<String, String> retrievedValMap = new Map<String, String>();
        JSONParser parser = JSON.createParser(retInfo);
        parser.nextToken();

        while (parser.nextToken() != null){
            parser.nextValue();
            String fieldName = parser.getCurrentName();         
            String fieldVal = parser.getText();
            if(fieldName != null && fieldVal != null){
                retrievedValMap.put(fieldName, fieldVal);
            }
        }
        return retrievedValMap;
    }
}