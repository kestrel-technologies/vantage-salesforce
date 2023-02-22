# Vantage object model

Objects and fields in the Vantage Sales & Service orgs (`kestrelvantage-dev`, `kestrelvantage-uat`,
`kestrelvantage-prod`). API names are what the code and flows use. Metadata that came over from the
Skyward org carries the `SKY_` prefix; Kestrel-era metadata uses plain names (no `Vantage_` prefix on
fields or objects).

Owner: Vantage Sales Systems (Mikael Lindqvist). Change process: a CL against `force-app/` with a
Perch ticket; field-level access goes in the same CL as the field (`profiles/`, code owner CorpEng CRM).

## Standard objects in use

Lead, Account, Contact, Opportunity, OpportunityLineItem, Product2, Pricebook2 (Standard and
"Vantage Price Book"), PricebookEntry, Quote, QuoteLineItem, Contract, Case, Task, User, Group (queues).

## Custom fields

`External_Id__c` (Text 40, External ID, unique, case-insensitive) exists on Lead, Account, Contact,
Opportunity, Case, Product2, Quote and Contract. It is the upsert key for integrations and data loads
(`ACC-000123`, `CON-…`, `LEAD-…`, `OPP-…`, `CASE-…`, `PROD-VDC-STD`, `QUO-…`, `CTR-…`).

| Object | Field | Type | Notes |
|---|---|---|---|
| Lead, Account | `Region__c` | Picklist | AMER, EMEA, APAC. Drives SDR and support queue routing. |
| Lead, Account | `Segment__c` | Picklist | Enterprise, Mid-Market. |
| Opportunity | `SE_Owner__c` | Lookup(User) | Solutions Engineer. Required from Solution Design. |
| Opportunity | `Legal_Review_Status__c` | Picklist | Not Required (default), Pending, Approved, Rejected. |
| Opportunity | `Contract_Term_Months__c` | Number(3,0) | Default 36. Copied to the Contract. |
| Opportunity | `Provisioning_Request__c` | Lookup(Provisioning_Request__c) | Set on Closed Won. |
| Case | `Product_Area__c` | Picklist | Data Cloud, Connect, Insight, Guard, Expert Services, Managed Operations, Academy, Portal & Account. |
| Case | `Perch_Ticket__c` | Text(20) | Engineering ticket when escalated past L2 (e.g. `VNT-1234`). |
| Case | `SLA_Response_Due__c`, `SLA_Resolution_Due__c` | DateTime | From Priority (P1 1h/8h, P2 4h/24h, P3 8h/72h, P4 24h/120h). |
| Case | `SLA_Breached__c` | Checkbox | A due date passed while the case was open. |
| Case | `Escalated_At__c` | DateTime | Stamped when Status moves to Escalated. |
| Case | `SKY_Case_Notes__c` | Rich Text | Skyward-era case notes; shown by the `skyCaseNotes` component. |
| Contract | `Opportunity__c` | Lookup(Opportunity) | The opportunity that created the contract. |

## Picklists that replace the platform defaults

| Field | Values |
|---|---|
| `Lead.LeadSource` | Web, Event, Partner Referral, Manual, Pulsar Nurture |
| `Lead.Status` | New, Working, Qualified, Converted, Disqualified |
| `Lead.Industry`, `Account.Industry` | Retail & CPG, Logistics & Transportation, Financial Services, Healthcare Providers & Payers, Manufacturing, Media |
| `Opportunity.StageName` | Discovery (10%), Solution Design (30%), Proposal/Quote (50%), Negotiation (75%), Closed Won (100%), Closed Lost (0%) |
| `Case.Origin` | Web, Email, Phone |
| `Case.Type` | Question, Problem, Feature Request, Knowledge |
| `Case.Status` | New, Working, Pending Customer, Escalated, Closed |
| `Case.Priority` | P1, P2, P3 (default), P4 |
| `Quote.Status` | Draft, Needs Review, In Review, Approved, Presented, Accepted, Denied, Rejected |
| `Product2.Family` | Data Cloud, Connect, Insight, Guard, Expert Services, Managed Operations, Academy |

Opportunity record types: New Business (default), Expansion, Renewal, Services Only.

## Custom objects and settings

### `Provisioning_Request__c` (Provisioning Request)

Created on Closed Won by `VantageProvisioningService`. Name is an autonumber `PR-{00000}`.
Internal and external sharing: Private.

| Field | Type | Notes |
|---|---|---|
| `Opportunity__c` | Lookup(Opportunity) | Lookup, not master-detail, so archiving opportunities does not cascade. |
| `Account__c` | Lookup(Account) | |
| `Edition__c` | Picklist | Standard, Enterprise, Enterprise Plus, Services Only (from the VDC line). |
| `CU_Commit__c` | Number(10,0) | Committed Compute Units (1,000 per `VDC-CU-1K` block). |
| `Status__c` | Picklist | Requested (default), Provisioning, Active, Failed. |
| `Requested_Go_Live__c` | Date | Close date + 30 days. |
| `External_Id__c` | Text(40), External ID | |


## Sharing (internal / external)

Account Public Read/Write / Private · Contact Controlled by Parent · Opportunity Public Read Only / Private ·
Case Public Read/Write/Transfer / Private · Lead Public Read/Write/Transfer / Private · Quote Controlled by
Parent · Provisioning Request Private / Private. Criteria-based sharing rules live in
`force-app/main/default/sharingRules/`.

## Queues

Lead: `SDR_AMER_Enterprise`, `SDR_AMER_MidMarket`, `SDR_EMEA`, `SDR_APAC`.
Case: `L1_Platform_AMER`, `L1_Platform_INTL` (Data Cloud, Guard), `L1_Apps_AMER`, `L1_Apps_INTL`
(Connect, Insight), `L1_Services` (Expert Services, Managed Operations, Academy, Portal & Account),
`L2_Escalations`.
