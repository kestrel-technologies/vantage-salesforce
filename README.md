# vantage-salesforce

SFDX source of the **Kestrel Vantage Sales & Service** orgs: metadata, Apex, Lightning Web Components and
Flows behind lead intake, the opportunity pipeline, Vantage Quoting, Closed Won provisioning and support
case routing. The org came over from Skyward Data in 2022; Skyward-era components carry the `SKY_` prefix.

Owners: Vantage Engineering (Salesforce) for `force-app/**`, CorpEng CRM Platform for profiles, permission
sets, connected apps and sharing, Vantage Business Systems for Flows. See `.github/CODEOWNERS`.

## Orgs

| Branch | Org | Alias | My Domain |
|---|---|---|---|
| `develop` | Vantage dev | `vantage-dev` | `https://kestrelvantage-dev.my.salesforce.com` |
| `uat` | Vantage UAT | `vantage-uat` | `https://kestrelvantage-uat.my.salesforce.com` |
| `main` | Vantage production | `vantage-prod` | `https://kestrelvantage-prod.my.salesforce.com` |

`main` is what runs in production. `develop` is the default branch; work lands there and is promoted
`develop → uat → main` once per sprint.

## Flightpath (CI/CD)

| Workflow | What it does |
|---|---|
| `ci` (`.github/workflows/ci.yml`) | Validation deploy to the org matching the target branch, `RunLocalTests`, per-class coverage gate (85%, KES-DEV-4). |
| `flightpath/reviewer` | Automated KES review of every CL; posts one verdict comment. Advisory on `main` until Q1 2027. |
| `deploy` (`.github/workflows/deploy.yml`) | Deploys a merged branch to its org. **Paused: deploy freeze CHG-2410** (KSS assessment of `vantage-prod`); runs show as skipped. |

CI signs in with the CorpEng Platform Automation connected app (JWT bearer). Actions secrets:
`SF_JWT_KEY`, `SF_CLIENT_ID_DEV`, `SF_CLIENT_ID_UAT`, `SF_CLIENT_ID_PROD`. Repository variable:
`FLIGHTPATH_DEPLOY_ENABLED`.

## Validate locally

Requires the Salesforce CLI (`npm install -g @salesforce/cli`) and a login to the dev org.

```bash
sf org login web --alias vantage-dev --instance-url https://kestrelvantage-dev.my.salesforce.com
sf project deploy validate --source-dir force-app --target-org vantage-dev --test-level RunLocalTests --wait 30
sf apex run test --target-org vantage-dev --code-coverage --result-format human --wait 10
```

Useful read-only commands:

```bash
sf org list metadata --metadata-type Flow --target-org vantage-dev
sf data query --query "SELECT Name, ApiVersion FROM ApexClass ORDER BY Name" --target-org vantage-dev
sf project retrieve start --metadata "Profile:Admin" --target-org vantage-dev --output-dir /tmp/retrieve
```

Deploying to `vantage-uat` or `vantage-prod` happens only through Flightpath. See
[docs/runbook-deploy.md](docs/runbook-deploy.md).

## Layout

```
force-app/main/default/
  classes/            Apex (SKY_* from Skyward, Vantage* Kestrel-era) and tests
  lwc/                Lightning Web Components
  flows/              record-triggered Flows (inventory: docs/flows.md)
  objects/            custom fields, Provisioning_Request__c, SKY_Legacy_Integration_Config__c
  profiles/ permissionsets/ connectedApps/ sharingRules/
  queues/ groups/ namedCredentials/ externalCredentials/ remoteSiteSettings/
docs/                 object model, flow inventory, deploy runbook
scripts/apex/         anonymous Apex helpers (read-mostly; run against dev first)
```

Not in source: user records, custom-setting values, connected-app secrets and certificates, the Experience
Cloud site bundle (managed in Setup until it is retrieved into source).

## Contributing

- One CL per change, linked to a Perch ticket in the title: `feat(flows): … [VNT-1234]`.
- Tests assert outcomes and include a `System.runAs` case (KES-DEV-2, KES-DEV-4).
- New or changed Flows: Description, an entry in `docs/flows.md`, a test (KES-DEV-6).
- No credentials, keys or tokens in source (KES-SEC-1). Use Named Credentials.

---

Kestrel Technologies is a fictional company created for an educational workshop. Nothing in this repository is a real credential, person or product. Mirrored from Roost by `roost-mirror`; CL metadata is preserved in commit trailers (`Roost-CL:`, `Reviewed-by:`).
