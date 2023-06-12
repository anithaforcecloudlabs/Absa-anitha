/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class EmailMessageCopyToCaseComment extends AbstractSobjectWorkflow {
    
    public override void executeAfter() {
          // minus 50 for truncate comment
       Integer charLimit   = 1200;// minus 50 for truncate comment
       Integer RegularCharLimit   = 2740;
        String delimiter = 'From: Rapid7 Support <support-@rapid7.com>';
        String truncationStatement = '...\n.\n.\n.\n<The body for this email is too large to display. Check the email tab to view the full email>';
        String truncationStatementjapanese = '...\n.\n.\n.\n<このメールの本文は大きすぎて表示できません。メールタブをチェックして、メール全体を表示します*>';
         String toaddressemail = 'support-japan@rapid7.com';
        Set<Id> caseIdsSet = new Set<Id>();
        Set<Id> noReopenCaseId = new Set<Id>();
        
        List<CaseComment> caseCommentList = new List<CaseComment>();
        
        //Added some logic to send the custom Notification as part of APPS-13198 By Raja Nangunoori
        Map<Id, Case> exportCaseMap = new Map<Id, Case>();
        /*Added some logic to not add regular comments with System User and add replied Email as comments 
        for Solution Offered Cases as part of APPS-16267 By Raja Nangunoori */
        Map<Id, Case> solnOfrdCaseMap = new Map<Id, Case>();
        Map<Id, String> solnOfrdContactEmailMap = new Map<Id, String>();
        List<EmailMessage> emailMsgCaseCommentInsert = new List<EmailMessage>();
        
        Map<String, String> userMap = new Map<String, String>();  
        Set<String> allEmailAddressSet = new Set<String>();
        Map<Id,Set<String>> emailIdAddressSetMap = new Map<Id,Set<String>>();
        String notificationTypeId = System.Label.CustomNotificationId;
        List<Map<String,Object>> notificationFlowMapLst = new List<Map<String,Object>>();
        CommunityDefaults__c communitySetting = CommunityDefaults__c.getOrgDefaults();
        String salesforceSystemID = communitySetting.SalesforceSystemUserId__c;
        String currentUserName = UserInfo.getName();
        String currentUserId   = (UserInfo.getUserId()).substring(0, 15);
        
        for (EmailMessage email: (List<EmailMessage>) this.records) {
            caseIdsSet.add(email.ParentId);
             //To get all Email addresses from Email -- APPS-13198
            Set<String> emailAddressSet = new Set<String>();
            if(String.isNotBlank(email.ToAddress)){
                emailAddressSet.addAll(email.ToAddress.split(','));                
            }
            if(String.isNotBlank(email.BccAddress)){                
                emailAddressSet.addAll(email.BccAddress.split(','));                 
            }
            if(String.isNotBlank(email.CcAddress)){                
                emailAddressSet.addAll(email.CcAddress.split(','));                 
            }
            allEmailAddressSet.addALL(emailAddressSet);
            emailIdAddressSetMap.put(email.Id, emailAddressSet);
        }
        if(!caseIdsSet.isempty()) {
            noReopenCaseId = updateCase(caseIdsSet);
             //APPS-13198 --> To check whether the case is Export Case or not
            Id exposrtCaseRTId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Export').getRecordTypeId();
            for(Case c: [Select Id, Status, RecordTypeId, CaseNumber, OpportunityName__r.Name, ContactEmail from Case where Id IN :caseIdsSet]){
                if(c.RecordTypeId ==exposrtCaseRTId){
                    exportCaseMap.put(c.Id,c);
                }
                /*Added some logic to not add regular comments with System User and add replied Email as comments 
                for Solution Offered Cases as part of APPS-16267 By Raja Nangunoori */
                if(c.Status == 'Waiting to Close'){
                    solnOfrdContactEmailMap.put(c.Id,c.ContactEmail);
                    if(userInfo.getUserId() !=salesforceSystemID){
                        solnOfrdCaseMap.put(c.Id,c);
                    }                    
                }                
            }
        }
        
         //APPS-13198 --> Get user Ids from Email addresses
        if(exportCaseMap.size()>0){           
            List<User> usrLst = [select Id, Email from User where IsActive = true AND Email IN :allEmailAddressSet];
            if(usrLst.size()>0){
                for(User u:usrLst){
                    userMap.put(u.Email, u.Id);
                }
            }
        }        
        for (EmailMessage email: (List<EmailMessage>) this.records) {
            if(!noReopenCaseId.contains(email.ParentId)) {
            String fromAddress;
            String attachmentNote = 'Attachment added in Files';
            if(email.FromAddress != null) {
                fromAddress = email.FromAddress;
            }
            else {
               fromAddress = email.ValidatedFromAddress;
            }
            String header              = 'From: '+ email.FromName + ' <' + fromAddress + '>\n';
            header                    += 'To: '+ email.ToAddress + '\n';
            header                    += email.CcAddress!=null?'CC: '+ email.CcAddress + '\n\n':'\n';
            
            String headerEnd          = 'Email Sent By : ' + currentUserName +'\n';
            if(currentUserId == salesforceSystemID) {
                headerEnd = '';
            }
            
            //create CaseComment Record
            CaseComment comment        = new CaseComment(ParentId=email.ParentId,
                                            IsPublished = true);
            /*HANDLE ASCII TEXT (NOT-HTML) EMAIL PARSING*/
            String notificationBody = '';
            System.debug('test email.TextBody.............'+email.TextBody);
            System.debug('test email.HtmlBody.............'+email.HtmlBody); // APPS-33889
            if (email.TextBody!=null) {
                try {
                    String body = email.TextBody;
                    Integer pos = body.indexOf(delimiter);
                    /* IF DELIMITER IS FOUND IN THE BODY OF THE EMAIL, STRIP CONTENT AFTER DELIMITER */
                    if(pos != -1) { 
                        body = body.substring(0, pos);
                    }   
                    /*ADD THE HEADER TO THE BODY BEFORE LENGTH TESTING */
                    body  = stripResponse(body);
                    system.debug('test after strip....'+body); // APPS-33889
                    //body = body + '\n' + header;
                    body = (email.HasAttachment == true ? body + '\n' + attachmentNote + '\n' + header + headerEnd : body + '\n' + header + headerEnd );
                    
                    system.debug('test after attachement....'+body); // APPS-33889
    
                    /*TEXT SHOULD BE IN UTF-8, SO RESPECT THE 4000 BYTE LIMIT AND CHECK TO SEE IF
                     lARGER THAN 4K. IF SO, TRUNCATE AT 3950 AND APPEND TRUNCATION COMMENT */
                    
                     comment.CommentBody = body;
                    String regex = '/[\u3000-\u303F]|[\u3040-\u309F]|[\u30A0-\u30FF]|[\uFF00-\uFFEF]|[\u4E00-\u9FAF]|[\u2605-\u2606]|[\u2190-\u2195]|\u203B/g';
                   Pattern regexPattern = Pattern.compile(regex);
                   Matcher regexMatcher = regexPattern.matcher(comment.CommentBody);
                   if (regexMatcher.find()) {
                       if(comment.CommentBody.length() > charLimit){
                           comment.CommentBody = comment.CommentBody.substring(0, 1280) + truncationStatementjapanese;
                       }
                   }
                   else{
                       if(comment.CommentBody.length() > RegularCharLimit){
                           comment.CommentBody = comment.CommentBody.substring(0, RegularCharLimit) + truncationStatement;
                       }
                   }
                }catch(System.DmlException e) {}
            }
            /* HANDLE HTML TEXT PARSING */
            else if (email.HtmlBody!=null) {
               try {
                   //String body = header + email.HtmlBody.replaceAll('\\<.*?>','');
                   String strBody = email.HtmlBody.replaceAll('\\<.*?>','');
                   system.debug('test strBody....'+strBody); // APPS-33889
                   String body = strBody.replaceAll('&nbsp;',' ');
                   system.debug('test body in html....'+body); // APPS-33889
                   Integer pos = body.indexOf(delimiter);

                   /*IF DELIMITER IS FOUND IN THE BODY OF THE EMAIL, STRIP CONTENT AFTER DELIMITER */
                   if( pos != -1) { 
                       body = body.substring(0, pos);
                   }
                   body  = stripResponse(body);
                   system.debug('test body in html after strip....'+body); // APPS-33889
                   
                   //body = body + '\n' + header;
                   body = (email.HasAttachment == true ? body + '\n' + attachmentNote + '\n' + header + headerEnd : body + '\n' + header + headerEnd );

                   system.debug('test body in html after attachment....'+body); // APPS-33889

                   /*TEXT SHOULD BE IN UTF-8, SO RESPECT THE 4000 BYTE LIMIT AND CHECK TO SEE IF
                     LARGER THAN 4K. IF SO, TRUNCATE AT 3950 AND APPEND TRUNCATION COMMENT */
                     
                    comment.CommentBody = body;
                    String regex = '/[\u3000-\u303F]|[\u3040-\u309F]|[\u30A0-\u30FF]|[\uFF00-\uFFEF]|[\u4E00-\u9FAF]|[\u2605-\u2606]|[\u2190-\u2195]|\u203B/g';
                   Pattern regexPattern = Pattern.compile(regex);
                   Matcher regexMatcher = regexPattern.matcher(comment.CommentBody);
                   if (regexMatcher.find()) {
                       if(comment.CommentBody.length() > charLimit){
                           comment.CommentBody = comment.CommentBody.substring(0, 1280) + truncationStatementjapanese;
                       }
                   }
                   else{
                       if(comment.CommentBody.length() > RegularCharLimit){
                           comment.CommentBody = comment.CommentBody.substring(0, RegularCharLimit) + truncationStatement;
                       }
                  
                        comment.CreatedById  = salesforceSystemID;
                } 
               }catch(System.DmlException e) {}
            }

            //APPS-13198 --> Send custom Notification to All ToAddress, Cc, Bcc users
                if(exportCaseMap.containskey(email.ParentId)){
                    Set<String> userIdSet = new Set<String>();
                    if(emailIdAddressSetMap.containskey(email.Id)){
                        for(String s :emailIdAddressSetMap.get(email.Id)){
                            if(userMap.containskey(s)){
                                userIdSet.add(userMap.get(s));
                            }
                        } 
                    }
                    if(userIdSet.size()>0){ 
                        notificationFlowMapLst.add(new Map<String,Object>{'notificationTypeId' => notificationTypeId,'notoficationTitle' => 'Custom Notification','notificationBody' => notificationBody,'notificationTargetId' => email.ParentId,'notificationRecipientIds' => userIdSet});
                    }                    
                }
                
                /*ADD COMENT TO COMMENTS ARRAY */
                /*Added some logic to not add regular comments with System User and add replied Email as comments 
                for Solution Offered Cases as part of APPS-16267 By Raja Nangunoori */
                if(solnOfrdContactEmailMap.containskey(email.ParentId) && email.Status !='3'){
                 //   String emailThreadId;
               //     System.debug('emailhtmlbody::'+email.HtmlBody);
                    if(email.HtmlBody != null && email.HtmlBody!=''){
                   //  emailThreadId = email.HtmlBody.substringBetween('ref:', ':ref');
                    }
                    // Call Apex method to retrieve case ID from email thread ID
                   // Id caseId = emailThreadId !=null?Cases.getCaseIdFromEmailThreadId(emailThreadId):null;
                   Id CaseId = email.parentId;
                   System.debug('---------------------CaseId-------------------- '+ CaseId);
                    if(caseId !=null && email.ParentId == caseId){
                        emailMsgCaseCommentInsert.add(email);
                    }
                }
                try { 
                    if(!solnOfrdCaseMap.containskey(email.ParentId)){
                        caseCommentList.add(comment);
                    }
                } catch ( System.DmlException e) {}
            }
        }
        
         /* IF THE COMMENTS ARRAY IS NOT EMPTY, TRY TO ASSERT TO DB. CATCH FAILURES GRACEFULLY - NO MSGS */
        if (!caseCommentList.isEmpty()) {
            try {            
                BypassFunctionalities.RunCaseCommentTrigger = false;          
                database.insert(caseCommentList,false);
                BypassFunctionalities.RunCaseCommentTrigger = true;
               //APPS-13198 -->
                if(notificationFlowMapLst.size()>0){
                    try{
                        for(Map<String,Object> flowMParamsMap :notificationFlowMapLst){
                            Flow.Interview.SendCustomNotificationForExportCase startFlow = new Flow.Interview.SendCustomNotificationForExportCase(flowMParamsMap);
                            startFlow.start();
                        }                                        
                    }
                    catch(Exception e){
                        system.debug('Exception Occured for Custom Notification '+e);
                    }
                }
                
            } catch ( System.DmlException e) {}
        }
        /*Add replied Email as comments for Solution Offered Cases as part of APPS-16267 By Raja Nangunoori */
        if(!emailMsgCaseCommentInsert.isEmpty()){
            EmailMessageCopyToCaseCommentsController.copyEmailMessagesToCaseComments(emailMsgCaseCommentInsert);
        }
    }

/******************************************************************
*   Method to execute before Insert/Update
*   Added by Raja Nangunoori
*   APPS-13198
*   Description: To append Case Number and Opp Name to the email body for Export cases while sending Email
******************************************************************/
    public override void executeBefore() {
        Set<Id> caseIdsSet = new Set<Id>();
        Map<Id, Case> caseMap = new Map<Id, Case>();    
        for (EmailMessage email: (List<EmailMessage>) this.records) {
            caseIdsSet.add(email.ParentId);
        }
        if(!caseIdsSet.isempty()) {
            Id exposrtCaseRTId =Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Export').getRecordTypeId();
            caseMap = new Map<Id, Case>([Select Id, CaseNumber, OpportunityName__r.Name from Case where Id IN :caseIdsSet and RecordTypeId=:exposrtCaseRTId]);
        }        
        for (EmailMessage email: (List<EmailMessage>) this.records) {
            system.debug('test before insert operation text body....'+email.textBody); // APPS-33889
            system.debug('test before insert operation html body....'+email.HtmlBody); // APPS-33889
            if(caseMap.containskey(email.ParentId)){
                Case c = caseMap.get(email.ParentId);
                String oppName = String.isNotBlank(c.OpportunityName__r.Name)?' on opportunity '+c.OpportunityName__r.Name:'';
                String newBody = 'New email from Export Case '+c.CaseNumber+oppName;               
                email.HtmlBody = String.isNotBlank(email.HtmlBody)?newBody+email.HtmlBody:newBody;
                //email.TextBody = String.isNotBlank(email.TextBody)?email.TextBody+'\n'+newBody:newBody;                 
            }
            
        }
    }

    public override String getClassName() {
        return EmailMessageCopyToCaseComment.class.getName();
    }

    public override Boolean qualify(Sobject newRecord,Sobject oldRecord) {
        Boolean qualified = false;
        if(Trigger.isInsert) {
            EmailMessage newEmail = (EmailMessage )newRecord;
            if(newEmail.ParentId != null && newEmail.ParentId.getSobjectType() == Case.SobjectType) {
                qualified = true;
            }
        }
        return qualified;
    }
    
    public static String stripResponse(String email) {
        String out = '';
        try {
            email = email.replaceAll('\r\n', '\n');
            email = email.replaceAll('>\nwrote:', '> wrote:');
            email = email.replaceAll('\nwrote:', 'wrote:');
            email = email.replaceAll('\n wrote:', ' wrote:');
            email = email.replaceAll(' \n wrote:', ' wrote:');
            Pattern p = Pattern.compile('(?m)^On .+<[^>]+> wrote:$');
            Matcher m = p.matcher(email);
            if (m.find()) {
                String turnText = email.substring(m.start(), m.end());
                turnText = turnText.replaceAll('\n', '');
                turnText = turnText.replaceAll('\r', '');

                if(m.start() > 0) { 
                    email = email.substring(0,m.start()-1)+'\n'+turnText+'\n'+email.substring(m.end()+1);
                }
                else {
                    email = '';
                }
                System.debug('email.....'+email);
            }
        
            String[] lines = email.split('\n');
            
        
            Boolean firstLine = true;
        
            for(integer i=0;i<lines.size();i++) { 
                Boolean addText = true;
                String line = lines[i];
                Integer j = i-1;
                if (!firstLine) { 
                    line  = line.replaceAll('\r\n', '');
                    line  = line.replaceAll('\r', '');
                    line = line.replace('\n','');        
                    if (line.startsWith('-----Original Message-----') || 
                        line.startsWith('--------------- Original Message ---------------') ||
                        (line.startsWith('On ') && line.endsWith('> wrote:')) ||
                        (line.startsWith('On ') && line.endsWith('> wrote: ')) ||
                        line.startsWith('Sent from my iPhone') || 
                        line.startsWith('From: ') || 
                        (line.startsWith('On ') && (line.endsWith('>') || line.endsWith('> ')))) {
                            if (line.startsWith('From: ') &&  i+1 < lines.size()) { 
                                if(lines[i+1].startsWith('Sent: ')) {
                                   break;
                                }
                            }
                            else if((line.startsWith('On ') && (line.endsWith('>') || line.endsWith('> '))) &&  i+1 < lines.size()) { 
                                if(lines[i+1].startsWith('wrote:')) {
                                   break;
                                }
                            }
                            else {
                                break;
                            }
                    }
                }
                
                firstLine = false;
                out += line + '\n';
            }
        }
        catch(Exception e) {
        
        }
        return out;
    }
    
    public static Set<Id> updateCase(Set<Id> caseIdSet) {
        List<Case> caseList = new List<Case>();
        Set<Id> noReopenCaseId = new Set<Id>();
        
        caseList = [Select Id,Status,CaseClosedDate__c from Case where Id IN:caseIdSet AND 
                        (status='Closed' OR status='Closed – No response from customer') AND RecordType.Name != 'Export'];
        for(Case caseRec : caseList) {
            caseRec.NotReOpenCase__c = true;
            noReopenCaseId.add(caseRec.Id);
        }
        update caseList;
        return noReopenCaseId;
    }
}