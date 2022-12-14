# vantage-salesforce

Salesforce metadata for the Vantage Sales & Service org, retrieved from the Skyward production org after the
move to Kestrel. Source format (SFDX).

## Orgs

| Branch | Org | Alias | My Domain |
|---|---|---|---|
| `develop` | Vantage dev | `vantage-dev` | `https://kestrelvantage-dev.my.salesforce.com` |
| `uat` | Vantage UAT | `vantage-uat` | `https://kestrelvantage-uat.my.salesforce.com` |
| `main` | Vantage production | `vantage-prod` | `https://kestrelvantage-prod.my.salesforce.com` |

## Working with the source

```bash
sf org login web --alias vantage-dev --instance-url https://kestrelvantage-dev.my.salesforce.com
sf project retrieve start --source-dir force-app --target-org vantage-dev
sf project deploy validate --source-dir force-app --target-org vantage-dev --test-level RunLocalTests
```

Releases to production are change sets for now (Sales Ops, C. Marsh).

## Skyward components

Everything prefixed `SKY_` came over from the Skyward org (2017-2019 code). Ported as-is so Birdseye and
the Account page components keep working; API versions were left at the Skyward values (47.0).

| Component | Notes |
|---|---|
| `SKY_AccountSearchController` + `skyAccountSearch` | Account search box (home page / utility bar) |
| `SKY_ContactExportController` + `skyContactExport` | "Export contacts" on the Account page |
| `skyCaseNotes` | Renders `Case.SKY_Case_Notes__c` |
| `SKY_BirdseyeSyncService` | Account sync to Birdseye (CHG-1740) |
| `SKY_Legacy_Integration_Config__c` | Birdseye login settings, maintained by Sales Ops in Setup |

---

Kestrel Technologies is a fictional company created for an educational workshop. Nothing in this repository is a real credential, person or product. Mirrored from Roost by `roost-mirror`; CL metadata is preserved in commit trailers (`Roost-CL:`, `Reviewed-by:`).
