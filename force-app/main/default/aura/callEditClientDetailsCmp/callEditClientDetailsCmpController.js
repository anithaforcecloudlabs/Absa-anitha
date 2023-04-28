({
	navigateToEditCmp: function (component, event, helper) {
		component.set("v.opportunityId", component.get("v.recordId"));
		component.find("recordLoader").reloadRecord();// Chandu W-012409
       
		var workspaceAPI = component.find("workspace");
		var onboardingClientDetailsTabId;
		workspaceAPI.getFocusedTabInfo().then(function (response) {
			onboardingClientDetailsTabId = response.tabId;
		});

		workspaceAPI.closeTab({ tabId: onboardingClientDetailsTabId });

		var Entitytype = component.get("v.opportunityRecord.Entity_Type__c");
		var executionLayerRequest = component.get("v.opportunityRecord.ExecutionLayerRequestID_Text__c");
		var id = component.get("v.opportunityRecord.Id");
		var recId = component.get("v.recordId");
		var checkXDS = false;
		// Commneted out as new production is not ready for the XDS check process.
		/*if (executionLayerRequest != null && executionLayerRequest != undefined && executionLayerRequest != "") {
			checkXDS = true;
		}*/

		if (checkXDS) {
			var evt = $A.get("e.force:navigateToComponent");
			evt.setParams({
				componentDef: "c:ABSA_ClientDetailsXDS",
				componentAttributes: {
					recordId: recId,
					EntityType: Entitytype
				}
			});
			evt.fire();
		} else {
			var evt = $A.get("e.force:navigateToComponent");
			var accId = component.get("v.opportunityRecord.AccountId");
			var oppId = component.get("v.opportunityRecord.Id");
			var processName = "EditFormExistingOpportunity";
			var processTypeVal = component.get("v.opportunityRecord.Process_Type__c");
			var clientType = component.get("v.opportunityRecord.Entity_Type__c");

			var registerdVATChecked =
				component.get("v.opportunityRecord.Account.VAT_Registration_Number__c") != null &&
				component.get("v.opportunityRecord.Account.VAT_Registration_Number__c") != undefined
					? true
					: false;

			if (accId != null && accId != "" && accId != undefined) {
				//Navigate to OnboardingClientDetails - Business Entities
				//Added by nitin shyamnani w-022656 for sole trader - farmer date:- 14-06-2022
				if (clientType != "INDIVIDUAL" && clientType != "Private Individual" && clientType != "Sole Trader" && clientType != "SOLE PROPRIETOR"  &&
				clientType != "Sole Trader - Farmer") {
					console.log("In Business accId : " + accId);
					evt.setParams({
						componentDef: "c:OnboardingClientDetails",
						componentAttributes: {
							accRecordId: accId,
							ProcessName: processName,
							opportunityRecordId: oppId,
							registerdVATChecked: registerdVATChecked,
							processType: processTypeVal,
							clientType:clientType,
							clientType2:clientType,
                            clientGroup:component.get("v.opportunityRecord.Account.Client_Group__c"),
                            placeOfResidence: component.get("v.opportunityRecord.Account.Place_of_Residence__c")
						}
					});
				}
				else if (
					clientType != "INDIVIDUAL" &&
					clientType != "Private Individual" &&
					clientType != "Sole Trader" &&
					clientType != "SOLE PROPRIETOR"
				) {
					console.log("In Business accId : " + accId);
					evt.setParams({
						componentDef: "c:OnboardingClientDetails",
						componentAttributes: {
							accRecordId: accId,
							ProcessName: processName,
							opportunityRecordId: oppId
						}
					});
				}

				//Navigate to OnboardingIndividualClientDetails - Individual and Sole Trader
				else {
					evt.setParams({
						componentDef: "c:OnboardingIndividualClientDetails",
						componentAttributes: {
							accRecordId: accId,
							ProcessName: processName,
							opportunityRecordId: oppId,
							isSoleTrader: true,
							clientTypeValue: clientType,
							iClientType: clientType,
							registerdVATChecked: registerdVATChecked,
							processType: processTypeVal
						}
					});
				}
			}

			evt.fire();

			helper.closeFocusedTab(component);
		}
	}
});