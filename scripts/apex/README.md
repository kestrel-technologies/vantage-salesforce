# Anonymous Apex helpers

Operational one-offs for the Vantage orgs. Run against `vantage-dev` first, then attach the output to the
Perch ticket before running anywhere else:

```bash
sf apex run --file scripts/apex/provisioning_backlog.apex --target-org vantage-dev
```

Rules: no credentials or custom-setting values in these files; every script is safe to re-run; scripts that
write default to a dry run (`Boolean DRY_RUN = true;` at the top).

| Script | Purpose | Writes |
|---|---|---|
| `provisioning_backlog.apex` | Closed Won opportunities with no Provisioning Request; optionally runs the provisioning service for them | only with `DRY_RUN = false` |
| `requeue_web_leads.apex` | Re-runs SDR queue resolution for open Web / Pulsar Nurture leads still owned by a user | only with `DRY_RUN = false` |
| `recalc_case_sla.apex` | Recomputes SLA due dates and routing for open cases created in the last N days | only with `DRY_RUN = false` |
| `queue_check.apex` | Lists the SDR and support queues the routing services expect and flags missing ones | no |
