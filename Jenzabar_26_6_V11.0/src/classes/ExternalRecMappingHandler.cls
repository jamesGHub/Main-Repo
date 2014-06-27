/*
 * Description : A class that contains the method that are related to the
 *               External Records mapping which handles all the functionality related 
 *               to External Records.
 */

public class ExternalRecMappingHandler{
  	public static Map<String,String> getExternalRecordFieldValues(Map<String,String> pLookupMap,Set<String> pObjectReferenced){
  	
  		Map<String,Boolean> refJsonContent = init(pLookupMap);
  		//System.debug('pLookup ')
        for(External_Record__c extItr : [SELECT Internal_ID__c,
                                                External_ID__c,
                                                Internal_Type__c
                                                FROM External_Record__c
                                                WHERE External_ID__c IN: pLookupMap.values() 
                                                AND Internal_Type__c IN: pObjectReferenced]
                                                ){
            System.debug('extItr==='+extItr);
            if(pLookupMap.containsKey(extItr.Internal_Type__c+','+extItr.External_ID__c) &&
                extItr.Internal_Type__c != null && extItr.External_ID__c != null && extItr.Internal_ID__c != null){
                refJsonContent.put(extItr.Internal_Type__c+','+extItr.External_ID__c,true);
                pLookupMap.put(extItr.Internal_Type__c+','+extItr.External_ID__c,extItr.Internal_ID__c);
            }
         }
         
         for(String str : refJsonContent.keySet()){
         	if(refJsonContent.get(str) == true){
         		refJsonContent.remove(str);
         	}
         }
         System.debug('refJsonContent==='+refJsonContent);
         if(!refJsonContent.isEmpty()){
         	//NotificationUtilityController.createStubRec(pLookupMap,refJsonContent,systemId);
         }
         return pLookupMap;
    }
  		//for()
  	
    
    /* This method will set all the lookup field those required ID to be mapped to false
     * so that we can check for stub record creation for those are not present.
     */
    public static Map<String,Boolean> init(Map<String,String> pJsonContent){
        System.debug('pJsonContent==='+pJsonContent);
        Map<String,Boolean> returnMap = new Map<String,Boolean>();
        for(String strItr : pJsonContent.keySet()){
            returnMap.put(strItr,false);
        }
        
        return returnMap;
    }
    
    /* This method will assign the internal ids to json content by mapping it through
     * external record mapping
     *//*
    public static Map<String,String> getExternalRecordsFieldsVal(Map<String,String> jsonContentMap,Map<String,String> jsonData,Set<String> internalType,String systemId){
        
        Map<String,Boolean> refJsonContent = init(jsonContentMap);
        for(External_Record__c extItr : [SELECT Internal_ID__c,
                                                External_ID__c,
                                                Internal_Type__c
                                                FROM External_Record__c
                                                WHERE External_ID__c IN: jsonContentMap.values() 
                                                AND Internal_Type__c IN: internalType]
                                                ){
            
            if(jsonContentMap.containsKey(extItr.Internal_Type__c+','+extItr.External_ID__c) &&
                extItr.Internal_Type__c != null && extItr.External_ID__c != null && extItr.Internal_ID__c != null){
                refJsonContent.put(extItr.Internal_Type__c+','+extItr.External_ID__c,true);
                jsonContentMap.put(extItr.Internal_Type__c+','+extItr.External_ID__c,extItr.Internal_ID__c);
            }
         }
         
         for(String str : refJsonContent.keySet()){
         	System.debug('str==='+str);
         	if(refJsonContent.get(str) == true){
         		refJsonContent.remove(str);
         	}
         }
         
         if(!refJsonContent.isEmpty()){
         	NotificationUtilityController.createStubRec(jsonContentMap,refJsonContent,systemId);
         }
        return jsonContentMap;
    }*/
}