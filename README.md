# vantage-salesforce

Salesforce metadata for the Vantage Sales & Service org, retrieved from the Skyward production org after the
move to Kestrel. Source format (SFDX).

## Orgs

| Org | Alias | My Domain |
|---|---|---|
| Vantage dev | `vantage-dev` | `https://kestrelvantage-dev.my.salesforce.com` |
| Vantage UAT | `vantage-uat` | `https://kestrelvantage-uat.my.salesforce.com` |
| Vantage production | `vantage-prod` | `https://kestrelvantage-prod.my.salesforce.com` |

## Working with the source

```bash
sf org login web --alias vantage-dev --instance-url https://kestrelvantage-dev.my.salesforce.com
sf project retrieve start --source-dir force-app --target-org vantage-dev
sf project deploy validate --source-dir force-app --target-org vantage-dev --test-level RunLocalTests
```

Releases to production are change sets for now (Sales Ops, C. Marsh).

---

Kestrel Technologies is a fictional company created for an educational workshop. Nothing in this repository is a real credential, person or product. Mirrored from Roost by `roost-mirror`; CL metadata is preserved in commit trailers (`Roost-CL:`, `Reviewed-by:`).
