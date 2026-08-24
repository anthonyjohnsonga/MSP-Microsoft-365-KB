# Microsoft OneDrive

MSP technician reference documentation for Microsoft OneDrive for Business and SharePoint sync.

## Contents

| File | Description |
|---|---|
| [Microsoft OneDrive Sync Troubleshooting.md](./Microsoft%20OneDrive%20Sync%20Troubleshooting.md) | Step-by-step guide for resolving OneDrive sync failures, missing sync icons, and SharePoint sync/shortcut issues — includes Quick Fix (relink), Full Fix (reset settings folder), and file recovery workflow (Path A / Path B) |
| [Microsoft OneDrive Over-Quota Report Guide.md](./Microsoft%20OneDrive%20Over-Quota%20Report%20Guide.md) | Quick guide for the PnP `Get-ODBOverQuotaUsers.ps1` script — connection requirements, delegated scopes, usage examples, CSV columns, scan modes, license quota tiers, and MSP gotchas (anonymized reports, GDAP, GCC High) |
| [Microsoft OneDrive Launch Failure Diagnosis with Process Monitor.md](./Microsoft%20OneDrive%20Launch%20Failure%20Diagnosis%20with%20Process%20Monitor.md) | Using ProcMon when OneDrive starts and instantly exits with no dialog, no event log entry, and no ODL logs — filter setup, working backwards from `Process_Exit`, the exit-status catalogue, noise to ignore, and the `DisableFileSyncNGSC` policy kill switch (worked example) plus the two separate OneDrive policy registry paths |

## Topics Covered

- OneDrive sync status icon (overlay) issues
- OneDrive not uploading or downloading changes
- SharePoint synced library and shortcut failures
- Resetting OneDrive local configuration state
- SharePoint file recovery before re-adding sync
- Identifying users over their OneDrive storage quota
- Multi-tenant / GDAP quota reporting for MSPs
- OneDrive launching and immediately exiting with no logs
- Process Monitor capture and trace reading
- OneDrive Group Policy / Intune policy registry locations
