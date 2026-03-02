# Runbook: deploying vantage-salesforce

Owner: CorpEng CRM Platform (Jon Licht). Applies to the three Vantage orgs. Flightpath is the only
supported path to an org; Setup changes in production are violations (Flightpath §9) and must be
reproduced in a CL within five business days (KES-DEV-3).

## Orgs and branches

| Branch | Org alias | My Domain | Who merges |
|---|---|---|---|
| `develop` | `vantage-dev` | `kestrelvantage-dev` | any engineer, 1 code-owner approval |
| `uat` | `vantage-uat` | `kestrelvantage-uat` | promotion CL from `develop` |
| `main` | `vantage-prod` | `kestrelvantage-prod` | promotion CL from `uat` (gate 3 advisory until Q1 2027) |

## Normal path

1. Open a CL against `develop`: title `<type>(<area>): <summary> [<ticket>]`, PR template filled in.
2. `ci` runs a validation deploy against `vantage-dev` with `RunLocalTests` and the per-class coverage
   gate (85%, KES-DEV-4). `flightpath/reviewer` posts its verdict table.
3. Code owner approves (see `.github/CODEOWNERS`); merge.
4. `deploy` deploys `develop` to `vantage-dev`.
5. Sprint promotion (every second Tuesday): CL `develop → uat`, then after UAT sign-off `uat → main`, title
   `chore(release): promote develop -> uat -> main (sprint YYYY-WW) [CHG-…]`, with an entry in `CHANGELOG.md`.

## Validate locally (read-only against the org)

```bash
sf org login web --alias vantage-dev --instance-url https://kestrelvantage-dev.my.salesforce.com
sf project deploy validate --source-dir force-app --target-org vantage-dev --test-level RunLocalTests --wait 30
sf apex run test --target-org vantage-dev --code-coverage --result-format human --wait 10
```

A validation deploy changes nothing in the org. Never run `sf project deploy start` against `vantage-uat` or
`vantage-prod` from a laptop.

## Order-sensitive components

- Custom setting and object definitions before classes that reference them.
- Profiles with login IP ranges last; check your own address is inside a range before deploying
  System Administrator, or use the CorpEng automation app (JWT, ENTSEC-EXC-1077).
- Connected apps: consumer secrets and certificates are never in source; Setup generates or holds them.

## Rollback

Revert the CL on the branch and let `deploy` redeploy the previous state. Destructive changes (deleted
fields, flows) need a `destructiveChanges.xml` in the revert CL and a CHG ticket.

## Break-glass

Production access outside Flightpath requires an approved CHG ticket and is recorded in the Setup Audit
Trail. Reproduce the change in a CL the same week.
