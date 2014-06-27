/*
 * Description : The queuer class which will insert the sObject by performing the content mapping  
 */

global class CreatesObjectQueuerController  {

	public static void execute(Set<Id> pQueueIds){
    	Map<Id,WrapperQueueContainer> queueWrapperMap = new Map<Id,WrapperQueueContainer>();
    	
    	// For Queue
    	Map<Id,Queue__c> queueMap = new Map<Id,Queue__c>();
    	// For Topic & Queue mapping
    	Map<Id,Set<Id>> queueTopicIdMap = new Map<Id,Set<Id>>();
    	Map<Id,Topic__c> queueTopicMap = new Map<Id,Topic__c>();
    	
    	// For Event & Queue mapping
    	Map<Id,Id> queueEventIdMap = new Map<Id,Id>();
    	Map<Id,Event__c> queueEventMap = new Map<Id,Event__c>();
    	
    	Set<Id> topicIds = new Set<Id>();
    	Set<Id> systemIds = new Set<Id>();
	    for(Queue__c queItr :[SELECT Id,
	    							 Event_ID__c,
						             Attempt_Count__c,
						             Queue_State_ID__c,
						             Retriever__c,
						             Topic_Id__c,
						             Source_System_Id__c
						             FROM Queue__c 
						             WHERE Id IN: pQueueIds]){
			
			if(!queueTopicIdMap.containsKey(queItr.Topic_Id__c)){
				queueTopicIdMap.put(queItr.Topic_Id__c,new Set<Id>{queItr.id});
			}
			else{
				queueTopicIdMap.get(queItr.Topic_Id__c).add(queItr.id);
			}
			queueMap.put(queItr.Id,queItr);			             	
	    	queueEventIdMap.put(queItr.Event_ID__c,queItr.id);
	    }
	    
	    for(Topic__c topicItr :[SELECT Id,
                                  	   Object_Name__c
                                  	   FROM Topic__c 
                                  	   WHERE Id IN: queueTopicIdMap.keySet()]){
    		if(queueTopicIdMap.containsKey(topicItr.id)){
    			for(Id IdItr : queueTopicIdMap.get(topicItr.id)){
    				queueTopicMap.put(IdItr,topicItr);
    			}
    		}
    		
    	}
	    
	    for(Event__c eventItr : [SELECT id,
                                         Event_State_ID__c,
                                         Topic_ID__c,
                                         Content_JSON__c,
                                         SourceSystem_ID__c 
                                         FROM Event__c 
                                         WHERE Id IN: queueEventIdMap.keySet()]){
			queueEventMap.put(queueEventIdMap.get(eventItr.id),eventItr);
			systemIds.add(eventItr.SourceSystem_ID__c);
		}
		
		topicIds.addAll(queueTopicIdMap.keySet());
		
		if(!pQueueIds.isEmpty()){
			for(Id queueIdItr : pQueueIds){
				queueWrapperMap.put(queueIdItr,new WrapperQueueContainer(queueMap.get(queueIdItr),queueTopicMap.get(queueIdItr),queueEventMap.get(queueIdItr),queueTopicMap.get(queueIdItr).Object_Name__c));
			}
		}
		
		for(Id queueItr : pQueueIds){
			NotificationUtilityController.parseJSON(queueWrapperMap);
		}
		ContentMappingHandler.contentMapping(topicIds,systemIds,queueWrapperMap);
		System.debug('queueWrapperMap==='+queueWrapperMap);
	}
}






















	/*

    //This method will call the create the sObject & update the queue status with success/error.
    public static void execute(Id queueId){
        String strTopicId = '';
        String jsonData = '';
        String sObjectName = '';
        String systemId = '';
        Map<String,List<Content_Mapping__c>> mapTopicRelatedContentMapping = 
                                                            new Map<String,List<Content_Mapping__c>>();
        Map<String,String> mapContent = new Map<String,String>();
        Map<String,String> mapJsonContent  = new Map<String,String>();
        Map<String,String> mapFields  = new Map<String,String>();
        List<Topic__c> topicObjLst = new List<Topic__c>();
         
        List<Queue__c> queObjLst = [SELECT Id,
                                           Event_ID__c,
                                           Attempt_Count__c,
                                           Queue_State_ID__c,
                                           Retriever__c,
                                           Topic_Id__c,
                                           Source_System_Id__c
                                           FROM Queue__c 
                                           WHERE Id=: queueId];
                                           
        if(!queObjLst.isEmpty()){                                   
            topicObjLst = [SELECT Id,
                                  Object_Name__c
                                  FROM Topic__c 
                                  WHERE Id=: queObjLst[0].Topic_Id__c];
        }
        
        if(!queObjLst.isEmpty()){   
            for(Event__c eventItr : [SELECT id,
                                            Event_State_ID__c,
                                            Topic_ID__c,
                                            Content_JSON__c,
                                            SourceSystem_ID__c 
                                            FROM Event__c 
                                            WHERE Id=: queObjLst[0].Event_ID__c]){
                      
            
                strTopicId = eventItr.Topic_ID__c;
                jsonData = eventItr.Content_JSON__c;
                systemId = eventItr.SourceSystem_ID__c;
            }
        }      
        System.debug(jsonData);  
        mapJsonContent = NotificationUtilityController.jsonParser(jsonData);
        mapContent =  ContentMappingHandler.contentMapping(strTopicId,mapJsonContent,'',systemId);
        
        if(!topicObjLst.isEmpty()){
            sObjectName = topicObjLst[0].Object_Name__c;
        }
        
        sObject sObjRec = NotificationUtilityController.getsObjectRec(sObjectName,mapContent);
        Database.saveResult result;
        try{
            result = Database.insert(sObjRec);
            queObjLst[0].Retriever__c = result.getId();
            queObjLst[0].Queue_State_ID__c = 'Complete';
            if(result.isSuccess()){
                NotificationUtilityController.createExeternalRecord(sObjectName,sObjRec,queObjLst[0].Source_System_Id__c);
            }   
        }
        catch(Exception e){
            System.debug('Exception Message :'+e.getMessage());
            queObjLst[0].Retriever__c = String.valueOf(e.getMessage());
            queObjLst[0].Queue_State_ID__c = 'Error';
        }
        finally{
            queObjLst[0].Attempt_Count__c = queObjLst[0].Attempt_Count__c != null ? queObjLst[0].Attempt_Count__c+1 : 1; 
            Database.saveResult queueResult = Database.update(queObjLst[0]);
        }
    }
    */