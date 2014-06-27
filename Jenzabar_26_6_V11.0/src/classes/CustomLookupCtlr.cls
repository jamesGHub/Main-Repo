global class CustomLookupCtlr {
    public boolean isEdit{get;set;}
    public string recId{get;set;}
    public List<Schema.FieldSetMember> fieldSetMemberList { get; set; }
    public sobject sObj{get; set;}
    public String objectName;
    public String fieldSetName{get; set;}
    public List<fieldWrap> lstFields{get; set;}
    public Map<String,String> mpIdtoName = new Map<String,String>();
    public List<String> lstId = new List<String>();
    public List<Reference__c> lstRef = new List<Reference__c>();
    
    public void setobjectName(String oName){
        if(objectName == null){
            objectName = oName;
            readFieldsetname();
            if(fieldSetName != null && fieldSetName != ''){
            	initData();
            }
        }
    }   
    public string getobjectName(){ 
        return objectName;
    }    
    public CustomLookupCtlr(){
        isEdit = false;
        recId = apexpages.currentPage().getParameters().get('id');
    }
    private void readFieldsetname(){
    	sobject sObjt; 
    	List<RecordType> rType;
    	if(recId != null && recId != '' && objectName != null && objectName != ''){
	        String query = 'SELECT RecordType.Name';
	        query += ' FROM '+objectName+' WHERE id=\''+recId+'\'';
	        sObjt =  Database.query(query);
	        if(sObjt != null){
	        	String rTypeid = String.valueOf(sObjt.get('RecordTypeId'));
	        	if(rTypeid != null && rTypeid != ''){
	        		rType = [Select Name From RecordType where id=:rTypeid limit 1];
	        	} 
	        }
	        if(rType != null && rType.size() > 0){
	        	List<Object_Field_Set_Mapping__c> lstfld = Object_Field_Set_Mapping__c.getAll().values();
	        	for(Object_Field_Set_Mapping__c fs:lstfld){
	        		if(fs.Object__c == objectName && fs.Record_Type__c == rType[0].Name){
	        			fieldSetName = fs.Field_Set_Name__c;
	        		}
	        	}
	        }    		
    	}
    }
    private void initData(){
        sObj = this.getsObj();
        if(sObj != null){
	        for(Schema.FieldSetMember mm:fieldSetMemberList){
	            Object ss = sObj.get(mm.fieldPath);
	            lstId.add(String.valueof(ss));
	        }
	        if(lstId.size() > 0){
	            lstRef = [Select id,Name from Reference__c where id=:lstId];
	        }
	        for(Reference__c ref:lstRef){
	            mpIdtoName.put(ref.id,ref.Name);
	        }
	        lstFields = new List<fieldWrap>();
	        for(Schema.FieldSetMember mem:fieldSetMemberList){
	            if(!mpIdtoName.isEmpty()){
	                String lkId = String.valueof(sObj.get(mem.fieldPath));
	                lstFields.add(new fieldWrap(mem.Label,mem.fieldPath,mpIdtoName.get(lkId),lkId));
	            }else{
	            	lstFields.add(new fieldWrap(mem.Label,mem.fieldPath,null,null));
	            }
	        }
        }       
    
    }
    private sobject getsObj() {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.readFieldSet(objectName,fieldSetName)) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, Name FROM '+objectName+' WHERE id=\''+recId+'\'';
        return Database.query(query);
    }
    
    public List<Schema.FieldSetMember> readFieldSet(String objectName,String fieldSetName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
        if(fieldSetName != null && fieldSetName != ''){
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
            fieldSetMemberList =  fieldSetObj.getFields();
            return fieldSetObj.getFields(); 
        }else{
            return null;
        }
    }      
    
    public pagereference doSave(){
        List<Reference__c> lstRef = new List<Reference__c>();
        Map<String,String> mpNametoId = new Map<String,String>();
        Set<String> setName = new Set<String>();
        for(fieldWrap fw:lstFields){
            setName.add(fw.fieldValue);
        }
        lstRef = [select id, name from Reference__c where name=:setName];
        for(Reference__c ref:lstRef){
            mpNametoId.put(ref.name,ref.id);
        }
        for(fieldWrap fr:lstFields){
            if(!mpNametoId.isEmpty() && mpNametoId.containsKey(fr.fieldValue)){
                sObj.put(fr.fieldApi,mpNametoId.get(fr.fieldValue));
            }else{
            	sObj.put(fr.fieldApi,null);
            }
        }
        try{
            upsert sObj;
        }catch(DmlException ex){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage());
            ApexPages.addMessage(myMsg);
            return null;        
        }
        isEdit = false;
        initData();
        return null;
    }
 
    public void Cancel(){
        isEdit = false;
        initData();
    }  
    public void Edit(){ 
        isEdit = true;
        initData();
    }  
    public class fieldWrap{
        public String fieldLabel{get;set;}
        public String fieldValue{get;set;}
        public String fieldApi{get;set;}
        public String refId{get;set;}
        public fieldWrap(String fieldLabel,String fieldApi,String rName,String lkId){
            this.fieldLabel = fieldLabel;
            this.fieldApi = fieldApi;
            if(rName != null && rName != ''){
            	 this.fieldValue = rName;
            }else{
            	 this.fieldValue = '';
            }
            if(lkId != null && lkId != '')
                this.refId = lkId;
            else
                this.refId = '';    
        }
    }
    
    
     @RemoteAction
    global static SObject[] findSObjects(string obj, string qry, string addFields) 
    {
    	
        /* List to store Reference Mapping records */        
        List<Reference_Mapping__c> refMapping = new List<Reference_Mapping__c>();
        
        
        /* Creating the filter text */
        String filter = ' like \'%' + String.escapeSingleQuotes(qry) + '%\'';
        
        /* Begin building the dynamic soql query */
        String soql = 'SELECT Name';      
        
        /* Adding the object and filter by name to the soql */
        soql += ' from ' + 'Reference__c' + ' where name' + filter;        
        //soql += ' from ' + 'Reference__c' + ' where name LIKE \''+'dua'+'%\'';        
        
        /* Querying the  */
        if (addFields != null) 
        {
                refMapping = [Select Reference_Record_Type__c from Reference_Mapping__c where Object_Name__c = :obj and API_Name__c = :addFields];			
        }
        
        if(refMapping.size()>0){
            soql += ' and RecordType.Name=\''+refMapping[0].Reference_Record_Type__c+'\'';
            soql += ' order by Name limit 20';
            
            List<sObject> L = new List<sObject>();
            try 
            {
                L = Database.query(soql);
                system.debug('>>>>>>L'+L);
            }
            catch (QueryException e) 
            {
                return null;
            }
        
            return L;
        }else{
            return null;
        }
   }
    
}