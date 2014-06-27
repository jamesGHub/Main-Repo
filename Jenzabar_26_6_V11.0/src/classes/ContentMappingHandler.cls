/*
 *  Description : A class that will be used for mapping the JSON content with salesforce's fields.
 */
public with sharing class ContentMappingHandler{
    
   
    public static final string Id = 'Id';
    
    // This wrapper class will hold all type of fields those are required for content mapping.
    /*public class FieldWrapper{
        String fieldName;
        String datatype;
        String referenceTo;
        String jsonField;
        String jsonValue;
        public FieldWrapper(String pFieldName,String pDatatype,String pReference,String pJsonField,String pJsonValue){
            fieldName = pFieldName;
            datatype = pDatatype;
            referenceTo = pReference;
            jsonField = pJsonField;
            jsonValue = pJsonValue;
        }
    }*/
    
     public class FieldContentWrapper{
        public String fieldName;
        public String datatype;
        public String referenceTo;
       
        public FieldContentWrapper(String pFieldName,String pDatatype,String pReference){
            fieldName = pFieldName;
            datatype = pDatatype;
            referenceTo = pReference;
        }
    }
    
    public class FieldValueDatatypeWrapper{
        public String fieldValue;
        public String datatype;
        
        public FieldValueDatatypeWrapper(String pFieldValue,String pDatatype){
            fieldValue = pFieldValue;
            datatype = pDatatype;
        }
        
    }
    
    public static void contentMapping(Set<Id> topicIds,Set<Id> systemIds,Map<Id,WrapperQueueContainer> pWrapper){
    	
    	//Map<String,FieldWrapper> valueFieldMap = new Map<String,FieldWrapper>();
    	//Map<Id,Content_Mapping__c> contentMappingMap = new Map<Id,Content_Mapping__c>();
    	Map<String,Map<String,FieldContentWrapper>> contentMappingMap = new Map<String,Map<String,FieldContentWrapper>>();
    	Map<String,String> lookupMap = new Map<String,String>();
    	Set<Id> queueIds = new Set<Id>();
    	Set<String> objectReferenced = new Set<String>();
    	queueIds.addAll(pWrapper.keySet());
    	
    	for(Content_Mapping__c objContentMappingRec : [SELECT Id,
                                                              JSONField__c,
                                                              JSONObject__c,
                                                              Local_Field__c,
                                                              LocalObject__c,
                                                              Source_ID__c 
                                                       FROM Content_Mapping__c 
                                                       WHERE  Source_ID__c IN:systemIds
                                                       AND Id IN (SELECT Content_Mapping__c
                                                                            FROM Topic_Content__c
                                                                            WHERE Topic__c IN:topicIds)])
		{	
			if(! String.isBlank(objContentMappingRec.JSONField__c) && 
    		   ! String.isBlank(objContentMappingRec.LocalObject__c) &&
    		   ! String.isBlank(objContentMappingRec.Local_Field__c)){
    			if(!contentMappingMap.containsKey(objContentMappingRec.LocalObject__c)){
    				contentMappingMap.put(objContentMappingRec.LocalObject__c,new Map<String,FieldContentWrapper>{objContentMappingRec.JSONField__c =>parseField(objContentMappingRec.Local_Field__c)});
    			}
    			else{
    				contentMappingMap.get(objContentMappingRec.LocalObject__c).put(objContentMappingRec.JSONField__c,parseField(objContentMappingRec.Local_Field__c));
    			}
    		}     
       }
       
       for(Id queueIdItr : queueIds){
       	 if(pWrapper.containsKey(queueIdItr)){
       	 	WrapperQueueContainer wrapItr = pWrapper.get(queueIdItr);
       	 	for(String strItr : wrapItr.jsonContent.keySet()){
       	 		if(wrapItr.jsonContent.containsKey(strItr)){
       	 			wrapItr.jsonData.put(contentMappingMap.get(wrapItr.objectName).get(strItr).fieldName,new FieldValueDatatypeWrapper(wrapItr.jsonContent.get(strItr),contentMappingMap.get(wrapItr.objectName).get(strItr).datatype));
       	 			if(!String.isBlank(contentMappingMap.get(wrapItr.objectName).get(strItr).datatype) &&
       	 			    String.valueOf(contentMappingMap.get(wrapItr.objectName).get(strItr).datatype).equalsIgnoreCase(Label.Content_Mapping_Lookup)){
       	 				lookupMap.put(contentMappingMap.get(wrapItr.objectName).get(strItr).referenceTo+','+wrapItr.jsonContent.get(strItr),wrapItr.jsonContent.get(strItr));
       	 				objectReferenced.add(contentMappingMap.get(wrapItr.objectName).get(strItr).referenceTo);
       	 			}
       	 		}
       	 	 }	
       	  }
       }
       System.debug('LookupMap1==='+lookupMap);
       lookupMap = ExternalRecMappingHandler.getExternalRecordFieldValues(lookupMap,objectReferenced);
       System.debug('LookupMap2==='+lookupMap);
    }
    
    
    // for(WrapperQueueContainer wrapItr : pWrapper.get(queueIdItr)){
           	/*for(String str : wrapItr.jsonContent.keySet()){
           		
           	}*/
       	 // }
    //This method will parse the JSON content & will create wrapper with all required details
    public static FieldContentWrapper parseField(String localFieldJSON){
        
        JSONParser parser = JSON.createParser(localFieldJSON);
        FieldContentWrapper wrapperObj;
        Map<String,String> wrapperMap = new Map<String,String>();
        String fieldName,fieldValue;
        String reference = '';
       
        while(parser.nextToken() != null){
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
                	fieldName = parser.getText();
                    parser.nextToken();
                    fieldValue = parser.getText();
                    wrapperMap.put(fieldName,fieldValue);
            }
        }
          
        if(!wrapperMap.containsKey(Label.Content_Mappng_ReferenceTo)){
            wrapperMap.put(Label.Content_Mappng_ReferenceTo,'');
        }
        
       
        wrapperObj = new FieldContentWrapper(wrapperMap.get(Label.Content_Mapping_FieldName),wrapperMap.get(Label.Content_Mapping_Datatype),wrapperMap.get(Label.Content_Mappng_ReferenceTo));
        return wrapperObj;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*
    
    
	//This method will change the json content's field with local fields by performing content mapping.
	public static Map<String,String> contentMapping(Id pTopicId,Map<String,String> jsonData,String ObjectType,String systemId){
    
        Map<String,String> fieldDTtypeMap = new Map<String,String>();
        Map<String,FieldWrapper> valueFieldMap = new Map<String,FieldWrapper>();
        Map<String,String> fieldValue = new Map<String,String>();
        Map<String,String> sffieldValueMap = new Map<String,String>();
        Set<String> objectString = new Set<String>();
        String internalType = '';
        
        for(Content_Mapping__c objContentMappingRec : [SELECT Id,
                                                              JSONField__c,
                                                              JSONObject__c,
                                                              Local_Field__c,
                                                              LocalObject__c,
                                                              Source_ID__c 
                                                       FROM Content_Mapping__c 
                                                       WHERE  Source_ID__c =: systemId
                                                       AND Id IN (SELECT Content_Mapping__c
                                                                            FROM Topic_Content__c
                                                                            WHERE Topic__c =: pTopicId)
                                                              ]){
                                                      
              internalType = objContentMappingRec.LocalObject__c;
              if(objContentMappingRec.JSONField__c != null && objContentMappingRec.Local_Field__c != null)
              {
      		      valueFieldMap.put(objContentMappingRec.JSONField__c,parseField(objContentMappingRec.Local_Field__c,objContentMappingRec.JSONField__c,jsonData.get(objContentMappingRec.JSONField__c)));
              }
        }
        
        System.debug('valueFieldMap==='+valueFieldMap);    
        for(FieldWrapper wrapItr : valueFieldMap.values()){
            
            if(String.valueOf(wrapItr.datatype).equalsIgnoreCase(Label.Content_Mapping_Lookup)){
                if(wrapItr.referenceTo != null){
                	fieldDTtypeMap.put(wrapItr.referenceTo+','+jsonData.get(wrapItr.jsonField),jsonData.get(wrapItr.jsonField));
            		objectString.add(wrapItr.referenceTo);
            	}
            }
            else if(String.valueOf(wrapItr.datatype).equalsIgnoreCase(Id)){
                fieldDTtypeMap.put(ObjectType+','+jsonData.get(wrapItr.jsonField),jsonData.get(wrapItr.jsonField));
            	objectString.add(ObjectType);
            }
        }
        
        fieldValue = ExternalRecMappingHandler.getExternalRecordsFieldsVal(fieldDTtypeMap,jsonData,objectString,systemId);
        
        for(FieldWrapper wrapItr : valueFieldMap.values()){
            
            if(fieldValue.containsKey(wrapItr.referenceTo+','+wrapItr.jsonValue))
            {
                jsonData.put(wrapItr.jsonField,fieldValue.get(wrapItr.referenceTo+','+wrapItr.jsonValue));
                sffieldValueMap.put(wrapItr.fieldName,fieldValue.get(wrapItr.referenceTo+','+wrapItr.jsonValue));
            }
            else if(fieldValue.containsKey(objectType+','+wrapItr.jsonValue))
            {
                jsonData.put(wrapItr.jsonField,fieldValue.get(wrapItr.referenceTo+','+wrapItr.jsonValue));
                sffieldValueMap.put(wrapItr.fieldName,fieldValue.get(objectType+','+wrapItr.jsonValue));
            }
            else
            {
                sffieldValueMap.put(wrapItr.fieldName,jsonData.get(wrapItr.jsonField));
            }
        }       
        
        return sffieldValueMap;
    }
    
    //This method will parse the JSON content & will create wrapper with all required details
    public static FieldWrapper parseField(String jsonLfield,String jsonField,String jsonValue){
        
        JSONParser parser = JSON.createParser(jsonLfield);
        FieldWrapper wrapperObj;
        Map<String,String> wrapperMap = new Map<String,String>();
        String fieldName,fieldValue;
        String reference = '';
       
        while(parser.nextToken() != null){
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
                
                    fieldName = parser.getText();
                    parser.nextToken();
                    fieldValue = parser.getText();
                    wrapperMap.put(fieldName,fieldValue);
            }
        }
          
        if(!wrapperMap.containsKey(Label.Content_Mappng_ReferenceTo)){
            wrapperMap.put(Label.Content_Mappng_ReferenceTo,'');
        }
       
        wrapperObj = new FieldWrapper(wrapperMap.get(Label.Content_Mapping_FieldName),wrapperMap.get(Label.Content_Mapping_Datatype),wrapperMap.get(Label.Content_Mappng_ReferenceTo),jsonField,jsonValue);
        return wrapperObj;
    }*/
}