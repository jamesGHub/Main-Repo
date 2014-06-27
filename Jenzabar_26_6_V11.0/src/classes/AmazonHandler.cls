public with sharing class AmazonHandler {
   public static final String ERROR_EVENTSTATE = 'Error';
	public static final String amazonBucketName = 'dev.crm.campusops.net';
    public AmazonHandler(){}
    /**
     * Method to create signature of amazon file
     * Argument: StringToSignByte and secret key of amazon account.
     * Return: Base64 encoded signature required to access file. 
     */
    private static String make_sig(string canonicalBuffer, String secretKey) {        
        String macUrl ;
        String signingKey = EncodingUtil.base64Encode(Blob.valueOf(secretKey));
        Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(canonicalBuffer),blob.valueof(secretKey)); 
        macUrl = EncodingUtil.base64Encode(mac);              
        return macUrl;
    }
    
    /**
     * Method to do httpcallout to Amazon S3 server to get information stored in object file.
     * After successfull/Failed callout, it updates event object with status and fetched content from Amazon file object.
     * Arugment : List of EventBean Object and Map of Id and System.
     * 
     */
    private static long getExpiration(){
    	 Datetime now = DateTime.now();
		 Datetime expireson = now.AddHours(1);
		 Long expirationLength = expireson.getTime()/1000;
		 return expirationLength;
    } 
    public static void getInfo(List<EventBean> newEventBeanList,Service__c serviceObj, Map<id,System__c> sysMap){
    	List<Event__c> updateEventList = new List<Event__c>();
    	for(EventBean newEventBeanInst : newEventBeanList){
		    
		    	Event__c newEventInst = newEventBeanInst.eventObj;
		    	System__c sourceSystemInst = sysMap.get(Id.ValueOf(newEventInst.SourceSystem_ID__c));
		    	for(Credentials__c credInst : sourceSystemInst.Credentials__r){
		    		  if(credInst.Service__c == serviceObj.id){ // if source system has multiple retrievers then credential should be used only for retriever associated to this class
		    		  	    try{
						    	String amazonBucketURL = credInst.URL__c +'/';
						    	String urlInfo = newEventBeanInst.link;
						   
								String fileName = urlInfo.subString(amazonBucketURL.length(),urlInfo.length());
						    	filename = EncodingUtil.urlEncode(filename, 'UTF-8');
						        
						    	Long Lexpires = getExpiration();
						    	
				        		String stringtosign = 'GET\n\n\n'+Lexpires+'\n/'+amazonBucketName+'/'+filename;
				        		String signed = make_sig(stringtosign,credInst.Credentials__c);
						        String codedsigned = EncodingUtil.urlEncode(signed,'UTF-8');
						        String url = amazonBucketURL+filename+'?AWSAccessKeyId='+credInst.Token__c+'&Expires='+Lexpires+'&Signature='+codedsigned;
					            Http h = new Http();
						        HttpRequest req = new HttpRequest();
						        req.setEndpoint(url);
						        req.setMethod('GET');
				       			HttpResponse res = h.send(req);
					            if(res != null && res.getBody() != null){
					                  newEventInst.Content_JSON__c = res.getBody();
					            }
					            if(res.getStatusCode() != 200){
					            	 newEventInst.Event_State_ID__c = ERROR_EVENTSTATE;
					            }
					            updateEventList.add(newEventInst);
		    		  	    }
		    		  	    catch(Exception ex){}
		    		  	    break; 	  	   
		    		  }
		    	}		    
    	}
    	try{
    		 update updateEventList;
    	}
    	catch(Exception e){
    	}	
    }
}