# Runbook: move svc.birdseye to Legacy Integration (Read)

Owner: Sales Ops (Birdseye) with Vantage Sales Systems. Tickets: REM-103, REM-104. Related: CHG-2412
(password rotation).

`svc.birdseye` is the Salesforce login Birdseye uses to read customer data. It has been on the System
Administrator profile since 2019-04 (moved off the original `Legacy Integration` profile to fix sync
permission errors). Birdseye only reads Accounts, Contacts, Opportunities and Cases, so this CL adds a
dedicated profile with exactly that and nothing else.

## What the profile grants

| | Legacy Integration (Read) | System Administrator (today) |
|---|---|---|
| Account, Contact, Opportunity, Case | Read | Everything |
| Custom fields on those objects | Read (the fields Birdseye syncs) | Everything |
| API Enabled | Yes | Yes |
| API Only User | Yes (no browser login) | No |
| Admin permissions (for example Modify All Data, View All Data, Manage Users) | None | All of them |

Moving `svc.birdseye` off System Administrator also takes it out of the org's admin-equivalent users
(REM-103): after the move it holds no permission that counts toward that list.

It is a new profile, not an edit of `Legacy Integration`: that profile still carries View All Data and
create/edit rights from 2019 and has no users; leave it alone until it is deleted under its own ticket.

## Steps (per org: dev, then uat, then prod, each after its promotion)

1. Deploy happens through Flightpath with this CL; confirm the profile exists:

   ```sh
   sf data query -o vantage-<env> -q "SELECT Id, Name FROM Profile WHERE Name = 'Legacy Integration (Read)'"
   ```

2. Pause the Birdseye sync job on the Birdseye host for the change window (Sales Ops).
3. Move the user (Setup > Users > svc.birdseye > Edit > Profile, or the CLI):

   ```sh
   sf data update record -o vantage-<env> -s User \
     -w "Username='svc.birdseye@vantage-<env>.kestrel.example'" -v "ProfileId=<Id from step 1>"
   ```

4. Remove the `SKY_Service_Account_Settings` permission set from the user if CHG-2412 has rotated the
   password by then (it only grants Password Never Expires).
5. Resume the sync job and watch one run: Birdseye account pages load, and Login History for
   `svc.birdseye` shows API logins with status Success.

## Rollback

Move the user back to System Administrator (step 3 with the old ProfileId) and resume the job. The
profile itself can stay; it has no users until step 3.

## Not in this CL

- Login IP ranges for the new profile: tracked under REM-106.
- Rotating the password and moving it out of Birdseye's configuration: CHG-2412 and REM-105.
