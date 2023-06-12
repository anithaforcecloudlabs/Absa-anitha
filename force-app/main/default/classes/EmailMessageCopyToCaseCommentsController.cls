/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class EmailMessageCopyToCaseCommentsController
{
    public static void copyEmailMessagesToCaseComments(List<EmailMessage> emails)
    {
        List<CaseComment> comments = new List<CaseComment>();
        for (EmailMessage email:emails)
        {
            Integer charLimit          = 1200;    // minus 50 for truncate comment
            Integer charLimit1          = 2740; 
            Id caseId                  = email.ParentId;
            CaseComment comment        = new CaseComment(ParentId=caseId);
            comment.IsPublished        = true;
            String delimiter           = 'From: Rapid7 Support <support@rapid7.com>';
            String truncationStatement = '...\n.\n.\n.\n<EMAIL TRUNCATED FOR DISPLAY PURPOSES>';
            String truncationStatementjapanese ='...\n.\n.\n.\n<このメールの本文は大きすぎて表示できません。メールタブをチェックして、メール全体を表示します*>';
            String toaddressemail = 'support-japan@rapid7.com';
            String header              = 'From: '+ email.FromName + ' <' + email.FromAddress + '>\n';
            header                    += 'To: '+ email.ToAddress + '\n';
            header                    += email.CcAddress!=null?'CC: '+ email.CcAddress + '\n\n':'\n';


//          -----------------------------------------------------------------------------------------
//          HANDLE ASCII TEXT (NOT-HTML) EMAIL PARSING
//          -----------------------------------------------------------------------------------------
            if (email.TextBody!=null) {
            
               String body =String.valueOf(email.TextBody) ;
               Integer pos = body.indexOf(delimiter);
              
//             --------------------------------------------------------------------------------------
//             IF DELIMITER IS FOUND IN THE BODY OF THE EMAIL, STRIP CONTENT AFTER DELIMITER
//             --------------------------------------------------------------------------------------
               if( pos != -1) { 
                   body = body.substring(0, pos);
               }

//             --------------------------------------------------------------------------------------
//             ADD THE HEADER TO THE BODY BEFORE LENGTH TESTING
//             --------------------------------------------------------------------------------------
               body = body + header;

//             --------------------------------------------------------------------------------------
//             TEXT SHOULD BE IN UTF-8, SO RESPECT THE 4000 BYTE LIMIT AND CHECK TO SEE IF
//             lARGER THAN 4K. IF SO, TRUNCATE AT 3950 AND APPEND TRUNCATION COMMENT
//             --------------------------------------------------------------------------------------
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
                       if(comment.CommentBody.length() > charLimit1){
                           comment.CommentBody = comment.CommentBody.substring(0, charLimit1) + truncationStatement;
                       }
                   }
           
                

//          -----------------------------------------------------------------------------------------
//          HANDLE HTML TEXT PARSING
//          -----------------------------------------------------------------------------------------
            } else if (email.HtmlBody!=null) {
               try {
               
                   String body = header + email.HtmlBody.replaceAll('\\<.*?>','');
                   Integer pos = body.indexOf(delimiter);

//                 ----------------------------------------------------------------------------------
//                 IF DELIMITER IS FOUND IN THE BODY OF THE EMAIL, STRIP CONTENT AFTER DELIMITER
//                 ----------------------------------------------------------------------------------
                   if( pos != -1) { 
                       body = body.substring(0, pos);
                   }

//                 ----------------------------------------------------------------------------------
//                 TEXT SHOULD BE IN UTF-8, SO RESPECT THE 4000 BYTE LIMIT AND CHECK TO SEE IF
//                 LARGER THAN 4K. IF SO, TRUNCATE AT 3950 AND APPEND TRUNCATION COMMENT
//                 ----------------------------------------------------------------------------------
                if(email.ToAddress==toaddressemail && body.length() > charLimit)
                {
                body = body.substring(0, 1280) + truncationStatementjapanese;
                }
                else if(body.length() > charLimit1)
                {
                    body = body.substring(0, charLimit1) + truncationStatement;
                }
                comment.CommentBody = body;
               
               } catch ( System.DmlException e) {}
            }

//          -----------------------------------------------------------------------------------------
//          ADD COMENT TO COMMENTS ARRAY
//          -----------------------------------------------------------------------------------------
            try {            
               comments.add(comment);
            } catch ( System.DmlException e) {
            }
        }
        
//      ---------------------------------------------------------------------------------------------
//      IF THE COMMENTS ARRAY IS NOT EMPTY, TRY TO ASSERT TO DB. CATCH FAILURES GRACEFULLY - NO MSGS
//      ---------------------------------------------------------------------------------------------
        if (!comments.isEmpty())
        {
            try {
                BypassFunctionalities.RunCaseCommentTrigger = false;            
               Database.insert (comments,false);
               BypassFunctionalities.RunCaseCommentTrigger = true;
           } catch ( System.DmlException e) {
               
           }
        }
    }
}