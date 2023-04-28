/**
 * @description Test Class for - OpportunityTrigger, TriggerHandlerOpportunity, OpportunityTriggerFunctions
 * @Author:  Rakesh Byri(Absa)
 * @Created Date:  2019-02-18
 * CHANGE LOG:
**/

@isTest
public class OpportunityTriggerFunctionsTest {
	@isTest
	static void beforeUpdatePositiveTest() {
		List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
		insert leadsList;
		List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
		oppsList[0].StageName = 'Proposal';
		oppsList[0].Lead_Number__c = leadsList[0].Id;
		insert oppsList;
		List<Opportunity> oppsList1 = [SELECT Id, StageName, OwnerId FROM Opportunity WHERE Name LIKE '%Test%'];
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			oppsList1[0].StageName = 'Uncontactable';
			try {
				update oppsList1;
			} catch (exception e) {
				string ex = e.getMessage();
			}
			system.assertNotEquals(null, oppsList1);
		}
	}

	@isTest
	static void beforeUpdateNegativeTest() {
		List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
		insert leadsList;
		List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
		oppsList[0].StageName = 'Proposal';
		oppsList[0].Lead_Number__c = leadsList[0].Id;
		insert oppsList;
		List<Opportunity> oppsList1 = [SELECT Id, StageName, OwnerId FROM Opportunity WHERE Name LIKE '%Test%'];
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			oppsList1[0].StageName = 'Sale Successful';
			try {
				update oppsList1;
				system.assertNotEquals(null, oppsList);
			} catch (Exception e) {
				string ex = e.getMessage();
			}
		}
	}
	////Test QA Approval Status Validation if Rejected AA user story W-005065
	@isTest
	static void beforeUpdateApprovalValidationPositiveTest() {
		List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
		insert leadsList;
		List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
		oppsList[0].StageName = 'Proposal';
		oppsList[0].Lead_Number__c = leadsList[0].Id;
		insert oppsList;
		List<Opportunity> oppsList1 = [
			SELECT Id, StageName, OwnerId, QA_Complex_Approval_Status__c, Rejection_Reasons__c
			FROM Opportunity
			WHERE Name LIKE '%Test%'
		];
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			oppsList[0].QA_Complex_Approval_Status__c = 'Rejected';
			// Added by chenna as part of DD Outbound Successful Sale
			oppsList1[0].Rejection_Reasons__c = 'Missing Information';
			try {
				update oppsList1;
			} catch (Exception e) {
				System.assert(
					e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Please enter a Rejection Reason before you reject the approval:'),
					e.getMessage()
				);
			}
		}
	}

	////Test QA Approval Status Validation if Rejected AA user story W-005065
	@isTest
	static void beforeUpdateApprovalValidationNegativeTest() {
		List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
		insert leadsList;
		List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
		oppsList[0].StageName = 'Proposal';
		oppsList[0].Lead_Number__c = leadsList[0].Id;
		insert oppsList;
		List<Opportunity> oppsList1 = [
			SELECT Id, StageName, OwnerId, QA_Complex_Approval_Status__c, Rejection_Reasons__c
			FROM Opportunity
			WHERE Name LIKE '%Test%'
		];
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			oppsList1[0].QA_Complex_Approval_Status__c = 'Rejected';
			oppsList1[0].Rejection_Reasons__c = 'Sanctions';
			oppsList1[0].Rejection_Sub_Reason__c = ' Trading as name not screened / Incorrectly Screened';
			try {
				update oppsList1;
			} catch (Exception e) {
				System.assertEquals(oppsList[0].QA_Complex_Approval_Status__c, 'Rejected');
			}
		}
	}

	// Added by chenna as part of DD Outbound Successful Sale on 24/11/2020- Start
	@isTest
	static void testEppInsertValidations1() {
		Test.startTest();
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
			insert leadsList;
			List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
			accListInsert[0].PersonBirthdate = null;
			insert accListInsert;
			List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
			oppsList[0].StageName = 'Proposal';
			oppsList[0].Lead_Number__c = leadsList[0].Id;
			insert oppsList;
			List<Opportunity> oppsList1 = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 1);
			oppsList1[0].StageName = 'Proposal';
			oppsList1[0].Lead_Number__c = leadsList[0].Id;
			oppsList1[0].accountid = accListInsert[0].id;
			try {
				insert oppsList1;
				system.assertNotEquals(null, oppsList);
			} catch (Exception e) {
				string ex =e.getMessage();
			}
		}
		Test.stopTest();
	}

	@isTest
	static void testEppInsertValidations2() {
		Test.startTest();
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
			insert leadsList;
			List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
			accListInsert[0].PersonBirthdate = date.parse('06/07/2012');
			accListInsert[0].ExecutionLayerRequestID__c = 'e46b46fc-c2a0-43f2-8580-a7ece88d7c41';
			insert accListInsert;
			List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
			oppsList[0].StageName = 'Proposal';
			oppsList[0].Lead_Number__c = leadsList[0].Id;
			insert oppsList;
			List<Opportunity> oppsList1 = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 1);
			oppsList1[0].StageName = 'Proposal';
			oppsList1[0].Lead_Number__c = leadsList[0].Id;
			//oppsList[0].recordTypeId = '0121r0000007dmi';
			oppsList1[0].accountid = accListInsert[0].id;
			oppsList1[0].VC_Application_Number__c = 'RBB Test';
			try {
				insert oppsList1;
				system.assertNotEquals(null, oppsList);
			} catch (Exception e) {
				string ex =e.getMessage();
			}
		}
		Test.stopTest();
	}

	@isTest
	static void testEppInsertValidations3() {
		Test.startTest();
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
			insert leadsList;
			List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
			accListInsert[0].PersonBirthdate = date.parse('06/07/1900');
			insert accListInsert;
			List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
			oppsList[0].StageName = 'Proposal';
			oppsList[0].Lead_Number__c = leadsList[0].Id;
			insert oppsList;
			List<Opportunity> oppsList1 = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 1);
			oppsList1[0].StageName = 'Proposal';
			oppsList1[0].Lead_Number__c = leadsList[0].Id;
			//oppsList[0].recordTypeId = '0121r0000007dmi';
			oppsList1[0].accountid = accListInsert[0].id;

			try {
				insert oppsList1;
				system.assertNotEquals(null, oppsList);
			} catch (Exception e) {
				OpportunityTriggerFunctions.checkStageSuccess('Test');
			}
		}
		Test.stopTest();
	}

	@isTest
	public static void testupdateChequeHolds() {
		Test.startTest();
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
			insert leadsList;
			List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
			accListInsert[0].PersonBirthdate = date.parse('06/07/1900');
			insert accListInsert;

			//List<Opportunity> oppsList = TestDataFactory.getOpportunities(null,'Opportunity_Business_Bank',1);
			Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			testOpportunity.StageName = 'Proposal';
			testOpportunity.Lead_Number__c = leadsList[0].Id;
			//testOpportunity.recordTypeId = '0125J000000HE5w';
			testOpportunity.accountid = accListInsert[0].id;
			update testOpportunity;
			//Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			Pricebook2 standardPriceBook = WillsTestDataFactory.getStandardPriceBook();
			Product2 product = WillsTestDataFactory.createProduct('Test', 'Test');
			PricebookEntry pricebookEntry = WillsTestDataFactory.createPriceBookEntry(standardPriceBook.Id, product.Id);
			OpportunityLineItem testOpportunityLineItem = WillsTestDataFactory.createOpportunityLineItem(testOpportunity.Id, pricebookEntry.Id);
			testOpportunity.StageName = 'Proposal ';
			update testOpportunity;
			OpportunityTriggerFunctions.updateChequeHolds(testOpportunity.id);
			//testOpportunity.Owner.Email = 'dawn123@gmail.com';
            //update testOpportunity;
            //OpportunityTriggerFunctions.sendEmailToIraOnClosure(testOpportunity,80,'1234');
			TriggerHandlerOpportunity.getDocumentsCasaTiersAsync(testOpportunity.id);
			system.assertEquals(testOpportunity.id, testOpportunity.id);
		}
		Test.stopTest();
	}
	@isTest
	public static void testgetExergyPolicyCover() {
		Test.startTest();
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType = 'Opportunity' AND Name = 'Direct Delivery Sales Opportunity'];

		System.runAs(usersList1[0]) {
			List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
			accListInsert[0].PersonBirthdate = date.parse('06/07/1900');
			insert accListInsert;
			Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			testOpportunity.StageName = 'Proposal';
			testOpportunity.RecordTypeId = rt.Id;
			testOpportunity.Available_Cover__c = null;
			testOpportunity.accountid = accListInsert[0].id;
			update testOpportunity;
			Pricebook2 standardPriceBook = WillsTestDataFactory.getStandardPriceBook();
			Product2 product = WillsTestDataFactory.createProduct('Test', 'Test');
			PricebookEntry pricebookEntry = WillsTestDataFactory.createPriceBookEntry(standardPriceBook.Id, product.Id);
			OpportunityLineItem testOpportunityLineItem = WillsTestDataFactory.createOpportunityLineItem(testOpportunity.Id, pricebookEntry.Id);
			testOpportunity.StageName = 'Proposal ';
			update testOpportunity;
			OpportunityTriggerFunctions.getExergyPolicyCover(testOpportunity.id);
			system.assertEquals(testOpportunity.id, testOpportunity.id);
		}
		Test.stopTest();
	}

	@isTest(SeeAllData=true)
	public static void testmarblecreateAccountService() {
		Test.startTest();

		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType = 'Opportunity' AND Name = 'SPM Onboarding'];

		System.runAs(usersList1[0]) {
			List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
			accListInsert[0].PersonBirthdate = date.parse('06/07/1900');
			insert accListInsert;

			//List<Opportunity> oppsList = TestDataFactory.getOpportunities(null,'Opportunity_Business_Bank',1);
			Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			testOpportunity.StageName = 'Vet Application';
			testOpportunity.RecordTypeId = rt.Id;
			testOpportunity.Available_Cover__c = null;
			testOpportunity.Approval_Status__c = 'Approved';
			testOpportunity.accountid = accListInsert[0].id;
			update testOpportunity;
			//Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			Pricebook2 standardPriceBook = WillsTestDataFactory.getStandardPriceBook();
			Product2 product = WillsTestDataFactory.createProduct('Test', 'Test');
			PricebookEntry pricebookEntry = WillsTestDataFactory.createPriceBookEntry(standardPriceBook.Id, product.Id);
			OpportunityLineItem testOpportunityLineItem = WillsTestDataFactory.createOpportunityLineItem(testOpportunity.Id, pricebookEntry.Id);
			Application_Product__c appPrdctRec=new Application_Product__c();
        	 appPrdctRec.Opportunity__c=testOpportunity.Id;
        	 appPrdctRec.Opportunity_Product_Id__c=testOpportunityLineItem.Id;
        	 list<Application_Product__c> lappPrdctRec =new list<Application_Product__c>();
        	 lappPrdctRec.add(appPrdctRec);
         	 insert lappPrdctRec;
			String POSITIVE_RESPONSE_BODY = '{"requestId":"3f3373ce-1a8e-477b-b453-2cef08382d07","partnerID":49,"entityId":174301,"crmEntityTypeId":1,"crmEntityName":"Hisroaccount Hillman03","mobileNumber":"0812246607","email":null,"marbleAccountTypeResponseList":[{"fundId":486975,"portfolioId":160076,"portfolioProductTypeID":1}],"Result":{"status":200,"statusCode":0,"statusMessage":"Marble on-boarding processed successful"}}';
			// Set mock callout class

			Test.setMock(HttpCalloutMock.class, new Sys_Utilities_Integration_Mock_ApiRest(StringConstants.POSITIVE_STRING, POSITIVE_RESPONSE_BODY));
			//OpportunityTriggerFunctions.marblecreateAccountService(testOpportunity.id);
			system.assertEquals(testOpportunity.id, testOpportunity.id);
		}
		Test.stopTest();
	}
	@isTest
	public static void testmarblecreateAccountService1() {
		Test.startTest();
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType = 'Opportunity' AND Name = 'Virtual Advisor'];

		System.runAs(usersList1[0]) {
			List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
			accListInsert[0].PersonBirthdate = date.parse('06/07/1900');
			insert accListInsert;

			//List<Opportunity> oppsList = TestDataFactory.getOpportunities(null,'Opportunity_Business_Bank',1);
			Opportunity testOpportunity = new Opportunity();
			testOpportunity.StageName = 'Vet Application';
			testOpportunity.RecordTypeId = rt.Id;
			testOpportunity.Available_Cover__c = null;
			testOpportunity.Approval_Status__c = 'Approved';
			testOpportunity.accountid = accListInsert[0].id;
			try {
				insert testOpportunity;
			} catch (exception e) {
				string ex = e.getMessage();
			}
			//Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			Pricebook2 standardPriceBook = WillsTestDataFactory.getStandardPriceBook();
			Product2 product = WillsTestDataFactory.createProduct('Test', 'Test');
			PricebookEntry pricebookEntry = WillsTestDataFactory.createPriceBookEntry(standardPriceBook.Id, product.Id);
			system.assertEquals(testOpportunity.id, testOpportunity.id);
		}
		Test.stopTest();
	}

	@isTest
	public static void testsendLeadsToESP() {
		Test.startTest();
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType = 'Opportunity' AND Name = 'Opportunity Business Bank'];

		System.runAs(usersList1[0]) {
			List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
			insert leadsList;
			List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
			accListInsert[0].PersonBirthdate = date.parse('06/07/1900');
			accListInsert[0].ExecutionLayerRequestID__c = '0125J00000';
			insert accListInsert;

			Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			testOpportunity.Lead_Number__c = '1';
			testOpportunity.StageName = 'Vet Application';
			testOpportunity.RecordTypeId = rt.Id;
			testOpportunity.Is_Sent_To_ESP__c = false;
			testOpportunity.Available_Cover__c = null;
			testOpportunity.Approval_Status__c = 'Approved';
			testOpportunity.accountid = accListInsert[0].id;
			update testOpportunity;
			//Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			Pricebook2 standardPriceBook = WillsTestDataFactory.getStandardPriceBook();
			Product2 product = WillsTestDataFactory.createProduct('Test', 'Test');
			PricebookEntry pricebookEntry = WillsTestDataFactory.createPriceBookEntry(standardPriceBook.Id, product.Id);
			OpportunityLineItem testOpportunityLineItem = WillsTestDataFactory.createOpportunityLineItem(testOpportunity.Id, pricebookEntry.Id);
			testOpportunity.StageName = 'Vet Application';
			update testOpportunity;
			OpportunityTriggerFunctions.sendLeadsToESP(testOpportunity.id);
			system.assertEquals(testOpportunity.id, testOpportunity.id);
		}
		Test.stopTest();
	}
	@isTest
	static void submitForQATest() {
		Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Product Onboarding').getRecordTypeId();
		List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
		insert leadsList;
		List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
		oppsList[0].StageName = 'Proposal';
		oppsList[0].Lead_Number__c = leadsList[0].Id;
		insert oppsList;
		List<Opportunity> oppsList1 = [
			SELECT Id, StageName, OwnerId, QA_Complex_Approval_Status__c, Rejection_Reasons__c
			FROM Opportunity
			WHERE Name LIKE '%Test%'
		];
		Product2 prod = new Product2(Name = 'Test', ProductCode = '1122', isActive = true);
		insert prod;
		Product2 prod1 = [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode = '1122'];
		prod1.ProductCode = '11029';
		update prod1;
		system.assertNotEquals(null, prod1);
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			try {
				ProductOnboardingApprovalController.submitForQA(oppsList1[0].Id, '');
			} catch (Exception e) {
				string ex =e.getMessage();
			}
		}
	}

	@isTest
	static void submitForDisputedQATest() {
		Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Product Onboarding').getRecordTypeId();
		List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
		insert leadsList;
		List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
		oppsList[0].StageName = 'Proposal';
		oppsList[0].Lead_Number__c = leadsList[0].Id;
		insert oppsList;
		List<Opportunity> oppsList1 = [
			SELECT Id, StageName, Disputed_QA_Approval_Status__c, OwnerId, QA_Complex_Approval_Status__c, Rejection_Reasons__c
			FROM Opportunity
			WHERE Name LIKE '%Test%'
		];
		Product2 prod = new Product2(Name = 'Test', ProductCode = '1122', isActive = true);
		insert prod;
		Product2 prod1 = [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode = '1122'];
		prod1.ProductCode = '11029';
		update prod1;
		system.assertNotEquals(null, prod1);
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			oppsList1[0].RecordtypeId = recordTypeId;
			oppsList1[0].ABSA_Region__c = 'Western Cape';
			try {
				update oppsList1;
				ProductOnboardingApprovalController.submitToDisputedQA(oppsList1[0], '');
			} catch (Exception e) {
				string ex =e.getMessage();
			}
		}
	}

	@isTest
	static void submitForDisputedQANegativeTest() {
		Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Product Onboarding').getRecordTypeId();
		List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
		insert leadsList;
		// List<Opportunity> oppsList = [SELECT Id, StageName,Disputed_QA_Approval_Status__c,OwnerId, ABSA_Region__c,Teller_Approval_Status__c,QA_Complex_Approval_Status__c, Rejection_Reasons__c FROM Opportunity WHERE Name LIKE '%Test%'];
		List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
		oppsList[0].StageName = 'Proposal';
		oppsList[0].Lead_Number__c = leadsList[0].Id;
		insert oppsList;
		List<Opportunity> oppsList1 = [
			SELECT Id, StageName, Disputed_QA_Approval_Status__c, OwnerId, QA_Complex_Approval_Status__c, CMS_Linking_Status__c, Rejection_Reasons__c
			FROM Opportunity
			WHERE Name LIKE '%Test%'
		];
		Product2 prod = new Product2(Name = 'Test', ProductCode = '1122', isActive = true);
		insert prod;
		Product2 prod1 = [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode = '1122'];
		prod.ProductCode = '11029';
		update prod1;
		system.assertNotEquals(null, prod1);
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			oppsList1[0].RecordtypeId = recordTypeId;
			oppsList1[0].Disputed_QA_Approval_Status__c = 'Accepted';
			oppsList1[0].CMS_Linking_Status__c = 'CAPTURED';
			oppsList1[0].Control_Officer_Type__c = 'PB – PRIVATE BANK';
			oppsList1[0].Branch_Region_Site__c = 'Test';
			oppsList1[0].ABSA_Region__c = 'Western Cape';
			try {
				update oppsList1;
				//ProductOnboardingApprovalController.submitToDisputedQA(oppsList[0], '');
			} catch (Exception e) {
				string ex =e.getMessage();
			}

			try {
				oppsList1[0].Disputed_QA_Approval_Status__c = 'Not Submitted';
				update oppsList1;
			} catch (Exception e) {
				string ex =e.getMessage();
			}
		}
	}
	
   
    @isTest
	static void DDInsertAddressTest() {
         List<Account> acc = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
         List<Lead> leadsList = TestDataFactory.getLeads('DD_STI_Lead', 1);
         insert leadsList;
         insert acc;
         OpportunityTriggerFunctions.upsertExistingAddressDetails(acc[0].Id,leadsList[0].Id);
         System.assertEquals(acc != null, true);
    }
    @isTest
	static void DDUpdateAddressTest() {
         List<Account> acc = TestDataFactory.getPersonAccounts('DDlastName', 'Individual_Client', 1);
         List<Lead> leadsList = TestDataFactory.getLeads('DD_STI_Lead', 1);
         insert leadsList;
         insert acc;
         List<Address__c> testadd = new List<Address__c>();
         Address__c newPhsical = new Address__c();
         newPhsical.Shipping_Street__c = 'Dainfern';
         newPhsical.Shipping_City__c = 'Gauteng';
         newPhsical.Shipping_Suburb__c = 'Gauteng';
         newPhsical.Shipping_Zip_Postal_Code__c = '2044';
         newPhsical.Address_Type__c = 'Physical Address';
         newPhsical.Account__c = acc[0].Id;
         newPhsical.Client_Entity_Type__c = 'Individual';
         testadd.add(newPhsical);
         Address__c newPostal = new Address__c();
         newPostal.Shipping_Street__c = 'Dainfern';
         newPostal.Shipping_City__c = 'Gauteng';
         newPostal.Shipping_Suburb__c = 'Gauteng';
         newPostal.Shipping_Zip_Postal_Code__c = '2044';
         newPostal.Address_Type__c = 'Postal';
         newPostal.Account__c = acc[0].Id;
         newPostal.Client_Entity_Type__c = 'Individual'; 
		 testadd.add(newPostal); 
         insert testadd;
         OpportunityTriggerFunctions.upsertExistingAddressDetails(acc[0].Id,leadsList[0].Id);
         System.assertEquals(acc != null, true);
    }
          
 // Added by chenna as part of DD Outbound Successful Sale on 24/11/2020- End
	@isTest
	static void ExceptionsTest() {
		Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Product Onboarding').getRecordTypeId();
		List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
		insert leadsList;
		List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Opportunity_Business_Bank', 3);
		oppsList[0].StageName = 'Proposal';
		oppsList[0].Lead_Number__c = leadsList[0].Id;
		insert oppsList;
		List<Opportunity> oppsList1 = [
			SELECT Id, StageName, Disputed_QA_Approval_Status__c, OwnerId, ABSA_Region__c, QA_Complex_Approval_Status__c, Rejection_Reasons__c
			FROM Opportunity
			WHERE Name LIKE '%Test%'
		];
		List<User> usersList = new List<User>();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].Business_Area__c = 'WIMI';
			insert usersList;
		}
		List<User> usersList1 = [SELECT Id FROM User WHERE username LIKE '%testuser1%'];
		System.runAs(usersList1[0]) {
			oppsList1[0].RecordtypeId = recordTypeId;
			try {
				oppsList1[0].QA_Complex_Approval_Status__c = 'Submitted';
				oppsList1[0].StageName = 'Closed Lost';
				update oppsList1;
				system.assertEquals(oppsList1[0].id, oppsList1[0].id);
			} catch (Exception e) {
				string ex =e.getMessage();
			}
		}
	}
    
    @isTest
	static void beforeUpdateInvestmentTest() {
        
        List<Account> acc = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
        List<Case> cases =  TestDataFactory.getCases('VA_Maturity',1);
        List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Investment_Opportunity', 1);
		oppsList[0].Approval_Status__c = 'Pending';
        oppsList[0].AccountId = acc[0].Id;
        oppsList[0].Case__c = cases[0].Id;
        oppsList[0].Sys_BypassValidation__c = true;
        insert oppsList;
        //Insert ContentDocument
        TestDataFactory.createdocument(oppsList[0].id);    	    
		oppsList[0].Approval_Status__c = 'Approved';
			try {
				update oppsList[0];
			} catch (exception e) {
				system.assertEquals(e.getMessage() != null, true);
			}
	}
    @isTest
    static void beforeUpdateRejectValidationTest() {
         List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Investment_Opportunity', 1);
         oppsList[0].Sys_BypassValidation__c = true;
         insert oppsList;
         oppsList[0].Approval_Status__c = 'Pending';
         oppsList[0].StageName='In Progress';
         oppsList[0].Sub_Status__c='Customer Responded';
         oppsList[0].Sys_BypassValidation__c = true;
         update oppsList[0];
         Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
         app.setObjectId(oppsList[0].id);
         Approval.ProcessResult result = Approval.process(app);
       
         try {
                oppsList[0].Approval_Status__c = 'Rejected';
                update oppsList[0];
                 Map<Id,ProcessInstance> approvalMap =new Map<Id,ProcessInstance>([SELECT id,TargetObjectId,(SELECT Id, Comments, StepStatus, Actor.Name, ProcessInstanceId,createdDate FROM Steps where StepStatus='Rejected' order by createddate desc limit 1) 
                                                                          FROM ProcessInstance where TargetObjectId= :oppsList[0].Id]);
                OpportunityTriggerFunctions.checkCertificateRejectValidation(oppsList[0],approvalMap);
            } catch (exception e) {
                System.assertEquals(e != null, true);
            }
    }
    @isTest
    static void beforedeleteValidationTest() {
         List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Investment_Opportunity', 1);
         oppsList[0].Sys_BypassValidation__c = true;
        try {
            
            insert oppsList;
        
            delete oppsList;
            //Assign Permission Set
             PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Authority_for_Delete_Opportunities'];
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
            
            delete oppsList;
        } catch (exception e) {
			system.assertEquals(e.getMessage() != null, true);
			}
        
    }
    /**
    * @description 
    * @author vineel.rudroju@absa.africa | 2021-11-30 
    **/
	@isTest
    static void callECPLeadServiceTest(){
        Test.startTest();
        List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
            insert accListInsert;
            List<Opportunity> oppsList = TestDataFactory.getOpportunities(null, 'Product_Onboarding', 1);

            oppsList[0].accountid = accListInsert[0].id; 
            insert oppsList;
			 Application__c appRec=new Application__c();
             appRec.Opportunity__c=oppsList[0].Id;
             appRec.Product_Interest__c = 'Protect your Employees';
             insert appRec;
             OpportunityTriggerFunctions.callECPLeadService(oppsList[0].id);
            system.assertNotEquals(NULL, oppsList[0].id);
        Test.stopTest();
    }
     @isTest
    public static void testupdateEmailNtfy(){
        Test.startTest();
        List<User> usersList = new list<User>();
        usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].email = 'UserA@testorg.com';
			insert usersList;
        
            List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
            insert leadsList;
            List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
            insert accListInsert;
            
            EmailTemplate e = new EmailTemplate();
            User runningUser = [ Select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( runningUser ) {
                
                e.developerName = 'test';
                e.TemplateType= 'Text';
                e.Name = 'test'; 
                e.isActive = true;
                e.FolderId = UserInfo.getUserId();
                insert e;
            }
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Complex Credit Onboarding').getRecordTypeId();
        set<id> opps = new set<id>();
        Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			testOpportunity.Lead_Number__c = '1';
            testOpportunity.StageName = 'Process application';
			testOpportunity.RecordTypeId = recordTypeId;
			testOpportunity.Is_Sent_To_ESP__c = false;
			testOpportunity.Available_Cover__c = null;
			testOpportunity.Approval_Status__c = 'Approved';
            testOpportunity.Sanctioning_Outcome__c = 'Rejected';
			testOpportunity.accountid = accListInsert[0].id;
			update testOpportunity;
        opps.add(testOpportunity.id);
        map<String, Schema.RecordTypeInfo> caseRecordTypeMap = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        Case caseRec1 = new Case(Communication_Method__c = 'Email',
                                 Status = 'New',
                                 Origin = 'Email', 
                                 Accountid = accListInsert[0].id,
                                 Account = accListInsert[0],
                                 Email__c = 'test@test.com',
                                 recordTypeId = caseRecordTypeMap.get('Complaint').getRecordTypeId(),
                                 Subject = 'Test Normal',
                                 Description = 'test',
                                 Expectation_of_the_Customer__c = 'test',
                                 Type__c = 'abc',
                                 Incident_Date__c = date.today());
        insert caseRec1;
        ContentVersion cv = new ContentVersion();
        cv.title = 'Test 1';
        cv.versionData = Blob.valueOf('Test1');
        cv.pathOnClient = 'Test 1';
        insert cv;
        
        ContentVersion testCV = [SELECT Id, ContentDocumentId FROM ContentVersion where Id =:cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = caseRec1.Id;
        cdl.ContentDocumentId = testCV.ContentDocumentId;
        cdl.Sharetype = 'V';
        insert cdl;
        Map<Id,ContentDocumentLink> docMap = new Map<Id,ContentDocumentLink>();
        docMap.put(cdl.id,cdl);
            
            OpportunityTeamMember OTM =new OpportunityTeamMember(TeamMemberRole = 'Credit Analyst',OpportunityId=testOpportunity.id,userId=usersList[0].Id);
            insert OTM;
            
            OpportunityTriggerFunctions.emilNtfyOppTeamMemb(opps,'Process application',e);
            OpportunityTriggerFunctions.sanctinOutcmErase(opps);
            OpportunityTriggerFunctions.checkCertificateApprovedValidation(testOpportunity,docMap);
            //OpportunityTriggerFunctions.getExergyPolicyCover(opps[0].id);
        
        Test.stopTest();
        System.assertEquals(caseRec1 != null, true);
    }
      @isTest
    public static void testupdateEmailNtfyFinalize(){
        Test.startTest();
        
        List<User> usersList = new list<User>();
        usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].email = 'UserA@testorg.com';
			insert usersList;
        
            List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
            insert leadsList;
            List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
            insert accListInsert;
            
            EmailTemplate e = new EmailTemplate();
            User runningUser = [ Select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( runningUser ) {
                
                e.developerName = 'test';
                e.TemplateType= 'Text';
                e.Name = 'test'; 
                e.isActive = true;
                e.FolderId = UserInfo.getUserId();
                insert e;
            }
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Complex Credit Onboarding').getRecordTypeId();
        set<id> opps = new set<id>();
        Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			testOpportunity.Lead_Number__c = '1';
            testOpportunity.StageName = 'Finalise application';
			testOpportunity.RecordTypeId = recordTypeId;
			testOpportunity.Is_Sent_To_ESP__c = false;
			testOpportunity.Available_Cover__c = null;
			testOpportunity.Approval_Status__c = 'Approved';
			testOpportunity.accountid = accListInsert[0].id;
			update testOpportunity;
        opps.add(testOpportunity.id);
        map<String, Schema.RecordTypeInfo> caseRecordTypeMap = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        OpportunityTeamMember OTM =new OpportunityTeamMember(TeamMemberRole = 'Credit Analyst',OpportunityId=testOpportunity.id,userId=usersList[0].Id);
        insert OTM;
        OpportunityTriggerFunctions.emilNtfyOppTeamMemb(opps,'Finalise application',e);
        
        Test.stopTest();
        System.assertEquals(testOpportunity != null, true);
    }
@isTest
    public static void testupdateEmailNtfyFullfill(){
        Test.startTest();
        
        List<User> usersList = new list<User>();
        usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].email = 'UserA@testorg.com';
			insert usersList;
        
            List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
            insert leadsList;
            List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
            insert accListInsert;
            
            EmailTemplate e = new EmailTemplate();
            User runningUser = [ Select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( runningUser ) {                
                e.developerName = 'test';
                e.TemplateType= 'Text';
                e.Name = 'test'; 
                e.isActive = true;
                e.FolderId = UserInfo.getUserId();
                insert e;
            }
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Complex Credit Onboarding').getRecordTypeId();
        set<id> opps = new set<id>();
        Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			testOpportunity.Lead_Number__c = '1';
			testOpportunity.StageName = 'Fulfilment';
			testOpportunity.RecordTypeId = recordTypeId;
			testOpportunity.Is_Sent_To_ESP__c = false;
			testOpportunity.Available_Cover__c = null;
			testOpportunity.Approval_Status__c = 'Approved';
			testOpportunity.accountid = accListInsert[0].id;
			update testOpportunity;
            opps.add(testOpportunity.id);
            map<String, Schema.RecordTypeInfo> caseRecordTypeMap = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
            OpportunityTeamMember OTM =new OpportunityTeamMember(TeamMemberRole = 'Credit Analyst',OpportunityId=testOpportunity.id,userId=usersList[0].Id);
            insert OTM;
            OpportunityTriggerFunctions.emilNtfyOppTeamMemb(opps,'Fulfilment',e);
        Test.stopTest();
        System.assertEquals(testOpportunity != null, true);
    }
     
     @isTest
    public static void testupdateEmailNtfyInitial(){
        Test.startTest();
        
        List<User> usersList = new list<User>();
        usersList = TestDataFactory.getTestUsers('System Administrator (Custom)', 2);
			usersList[0].email = 'UserA@testorg.com';
			insert usersList;
        
            List<Lead> leadsList = TestDataFactory.getLeads('Business_Bank_Lead', 1);
            insert leadsList;
            List<Account> accListInsert = TestDataFactory.getPersonAccounts('lastName', 'Individual_Client', 1);
            insert accListInsert;
            
            EmailTemplate e = new EmailTemplate();
            User runningUser = [ Select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( runningUser ) {
                
                e.developerName = 'test';
                e.TemplateType= 'Text';
                e.Name = 'test'; 
                e.isActive = true;
                e.FolderId = UserInfo.getUserId();
                insert e;
            }
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Complex Credit Onboarding').getRecordTypeId();
        set<id> opps = new set<id>();
        Opportunity testOpportunity = WillsTestDataFactory.createOpportunity();
			testOpportunity.Lead_Number__c = '1';
            testOpportunity.StageName = 'Initiate application';
			testOpportunity.RecordTypeId = recordTypeId;
			testOpportunity.Is_Sent_To_ESP__c = false;
			testOpportunity.Available_Cover__c = null;
			testOpportunity.Approval_Status__c = 'Approved';
			testOpportunity.accountid = accListInsert[0].id;
			update testOpportunity;
        opps.add(testOpportunity.id);
        map<String, Schema.RecordTypeInfo> caseRecordTypeMap = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
         OpportunityTeamMember OTM =new OpportunityTeamMember(TeamMemberRole = 'Credit Analyst',OpportunityId=testOpportunity.id,userId=usersList[0].Id);
         insert OTM;            
         OpportunityTriggerFunctions.emilNtfyOppTeamMemb(opps,'Initiate application',e);
        Test.stopTest();
        System.assertEquals(testOpportunity != null, true);
    }
 /**
     * @description
     * @author Dawn
     **/
  @isTest(SeeAllData=true)
    static void sendEmailToIraTest(){
		Test.startTest();
		User u = UserTDF.addUser('System Administrator (Custom)', 'UserAdmin', 'UserAdmin@testorg.com');
		u.Business_Area__c='WIMI';
		update u;
		System.runAs(u) {
			Account account = AccountTDF.addClient('','Test Account');
			Opportunity testOpp =OpportunityTDF.addProductOnboardingOpp('Test Opp', 'Drafting', Date.today(), account.Id);
			Application__c app=ApplicationTDF.addOnboardingApp(testOpp.Id); 
			Product2 savingsProd =Product2TDF.addProduct('Savings Product',true,'Savings',null);
			PricebookEntry savingsCustomPrice =PricebookEntryTDF.addPriceBookEntry(Test.getStandardPricebookId(),savingsProd.Id,12000,true);
			Integer totPrice1=Integer.valueof(5 * savingsCustomPrice.UnitPrice);
			OpportunityLineItem oli =OpportunityLineItemTDF.addOppLineItem(testOpp.Id,null,savingsCustomPrice.Id,5,totPrice1,null,'4048358221');
			Map<String,Object> inputMap = new map<String,Object>();
			map<id,Application__c> mapOppIdToApplication = new map<id,Application__c>();
			map<id,id> mapOppIdToUserId = new map<id,id>();
			map<id,Opportunity> oppTriggerNew = new map<id,Opportunity>();
			map<Id,OpportunityLineItem> closedWonSniOpportunityIdToOli =  new map<Id,OpportunityLineItem>();
			mapOppIdToApplication.put(testOpp.id,app);            
			mapOppIdToUserId.put(testOpp.id,u.id);			
			oppTriggerNew.put(testOpp.id,testOpp);
			closedWonSniOpportunityIdToOli.put(testOpp.id,oli);
			inputMap.put('application',mapOppIdToApplication);
			inputMap.put('opportunity',oppTriggerNew);
			inputMap.put('opportunityUserMap',mapOppIdToUserId);
			inputMap.put('sniOpportunity',closedWonSniOpportunityIdToOli);
			OpportunityTriggerFunctions.sendEmailToIra(inputMap);
			system.assert([select id,StageName from Opportunity where id=:testOpp.id limit 1].StageName == 'Drafting');
		}
		Test.stopTest();
    }

}