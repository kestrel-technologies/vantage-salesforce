/**
 * Closed Won fan-out, called by the Opportunity_Closed_Won flow.
 * Per opportunity: one Provisioning_Request__c (edition from the VDC line, else
 * Services Only), one draft Contract, one CSM kickoff Task for the opportunity
 * owner; links the request back to the opportunity and stamps
 * Account.Customer_Since__c on the first win. Idempotent: opportunities that
 * already have a request are skipped.
 * Owner: Vantage Sales Systems
 */
public with sharing class VantageProvisioningService {
    @TestVisible private static final Map<String, String> EDITION_BY_CODE = new Map<String, String>{
        'VDC-STD' => 'Standard',
        'VDC-ENT' => 'Enterprise',
        'VDC-ENTP' => 'Enterprise Plus'
    };
    @TestVisible private static final String SERVICES_ONLY = 'Services Only';
    @TestVisible private static final Integer DEFAULT_TERM_MONTHS = 36;
    @TestVisible private static final Integer KICKOFF_DUE_DAYS = 5;
    @TestVisible private static final Integer GO_LIVE_DAYS = 30;

    @InvocableMethod(label='Closed Won fan-out' description='Creates the provisioning request, draft contract and CSM kickoff task for Closed Won opportunities.')
    public static void onClosedWon(List<Id> opportunityIds) {
        Set<Id> oppIds = new Set<Id>(opportunityIds);
        oppIds.remove(null);
        for (Provisioning_Request__c existing : [SELECT Opportunity__c FROM Provisioning_Request__c
                                                 WHERE Opportunity__c IN :oppIds WITH USER_MODE]) {
            oppIds.remove(existing.Opportunity__c);
        }
        if (oppIds.isEmpty()) return;

        List<Opportunity> opps = [
            SELECT Id, Name, AccountId, OwnerId, CloseDate, Contract_Term_Months__c, Account.Customer_Since__c,
                   (SELECT Quantity, Product2.ProductCode FROM OpportunityLineItems)
            FROM Opportunity WHERE Id IN :oppIds WITH USER_MODE
        ];

        List<Provisioning_Request__c> requests = new List<Provisioning_Request__c>();
        List<Contract> contracts = new List<Contract>();
        List<Task> tasks = new List<Task>();
        Map<Id, Account> accountUpdates = new Map<Id, Account>();
        for (Opportunity opp : opps) {
            String edition = SERVICES_ONLY;
            Decimal cuBlocks = 0;
            for (OpportunityLineItem li : opp.OpportunityLineItems) {
                String code = li.Product2 == null ? null : li.Product2.ProductCode;
                if (EDITION_BY_CODE.containsKey(code)) edition = EDITION_BY_CODE.get(code);
                if (code == 'VDC-CU-1K' && li.Quantity != null) cuBlocks += li.Quantity;
            }
            Date start = opp.CloseDate != null ? opp.CloseDate : Date.today();
            requests.add(new Provisioning_Request__c(
                Opportunity__c = opp.Id, Account__c = opp.AccountId, Edition__c = edition,
                CU_Commit__c = cuBlocks * 1000, Status__c = 'Requested', Requested_Go_Live__c = start.addDays(GO_LIVE_DAYS)));
            if (opp.AccountId != null) {
                Integer term = opp.Contract_Term_Months__c != null ? opp.Contract_Term_Months__c.intValue() : DEFAULT_TERM_MONTHS;
                contracts.add(new Contract(AccountId = opp.AccountId, Opportunity__c = opp.Id, StartDate = start,
                    ContractTerm = term, Status = 'Draft'));
                if (opp.Account.Customer_Since__c == null) {
                    accountUpdates.put(opp.AccountId, new Account(Id = opp.AccountId, Customer_Since__c = start));
                }
            }
            tasks.add(new Task(Subject = 'CSM kickoff: ' + opp.Name, OwnerId = opp.OwnerId, WhatId = opp.Id,
                ActivityDate = Date.today().addDays(KICKOFF_DUE_DAYS), Priority = 'Normal'));
        }

        List<Provisioning_Request__c> insertedRequests = Security.stripInaccessible(AccessType.CREATABLE, requests).getRecords();
        insert insertedRequests;
        insert Security.stripInaccessible(AccessType.CREATABLE, contracts).getRecords();
        insert Security.stripInaccessible(AccessType.CREATABLE, tasks).getRecords();

        List<Opportunity> oppUpdates = new List<Opportunity>();
        for (Provisioning_Request__c pr : insertedRequests) {
            oppUpdates.add(new Opportunity(Id = pr.Opportunity__c, Provisioning_Request__c = pr.Id));
        }
        update Security.stripInaccessible(AccessType.UPDATABLE, oppUpdates).getRecords();
        if (!accountUpdates.isEmpty()) {
            update Security.stripInaccessible(AccessType.UPDATABLE, accountUpdates.values()).getRecords();
        }
    }
}
