# Flow inventory

Every active Flow in the Vantage orgs, per KES-DEV-6 §2: owner, trigger, run mode and the test that
covers it. A CL that adds or changes a Flow updates this table in the same CL (Flightpath checklist).

Run mode is **user context (Default)** for every Flow below; a Flow that needs system context must say
why in its Description and get code-owner approval (KES-DEV-6 §4).

| Flow (API name) | Owner | Trigger | What it does | Run mode | Test |
|---|---|---|---|---|---|
| `Vantage_Lead_Routing` | Vantage Sales Systems | Lead, after save: create; update when Region or Segment changes while a queue owns the lead | Assigns the SDR queue for region × segment via `VantageLeadRoutingService`; manual leads owned by an SDR are left alone | Default | [`VantageLeadRoutingService_Test`](../force-app/main/default/classes/VantageLeadRoutingService_Test.cls) |
| `Vantage_Opportunity_Stage_Gates` | Vantage Sales Systems | Opportunity, before save: update when StageName changes | Blocks Solution Design without an SE Owner, Proposal/Quote without a synced Quote, Negotiation over $250k without Legal Review = Approved | Default | [`VantageOpportunityStageGates_Test`](../force-app/main/default/classes/VantageOpportunityStageGates_Test.cls) |
| `Vantage_Quoting_Pricing` | Vantage Sales Systems | QuoteLineItem, after save: create; update when UnitPrice or Quantity changes | Applies the 8% platform commit discount (10+ CU blocks) and the 5% services attach discount; requests discount approval above 20% | Default | [`VantagePricingService_Test`](../force-app/main/default/classes/VantagePricingService_Test.cls) |
| `Vantage_Case_Routing` | Vantage Support Operations | Case, after save: create; escalation; Priority change (trigger order 20) | Routes to the L1 queue for product area × region, escalations to L2, sets SLA due dates | Default | [`VantageCaseRoutingService_Test`](../force-app/main/default/classes/VantageCaseRoutingService_Test.cls) |
| `Vantage_Closed_Won_Provisioning` | Vantage Sales Systems | Opportunity, after save: update when StageName changes to Closed Won | Creates the Provisioning Request, a draft Contract and the CSM kickoff task; stamps Customer Since | Default | [`VantageProvisioningService_Test`](../force-app/main/default/classes/VantageProvisioningService_Test.cls) |

## Conventions

- API names start with `Vantage_`; labels match the API name with spaces.
- Logic that needs queries or loops lives in an invocable Apex class (`Vantage*Service`) so the Flow stays
  a thin trigger and the class carries the tests and assertions (KES-DEV-2).
- No hard-coded record Ids: queues are resolved by developer name.
- Record-triggered Flows on the same object set an explicit trigger order.
- Inactive versions beyond the two most recent are deleted at each sprint promotion (KES-DEV-6 §6).

Last reviewed: 2026-09-21 (sprint 2026-38), Mikael Lindqvist.
