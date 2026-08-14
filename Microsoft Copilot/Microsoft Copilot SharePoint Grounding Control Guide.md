# Controlling Copilot Access to SharePoint Content

**Applies to:** Microsoft 365 Copilot, SharePoint Online, SharePoint Advanced Management (SAM)  
**Scope:** Restricting what Microsoft 365 Copilot can retrieve and cite from SharePoint Online using Restricted Content Discovery (RCD) — scoping the request, the licensing gate, site discovery and classification, applying and validating the control, and rollback. Reusable as an engagement guide for M365 Copilot readiness work. Does not cover blocking Copilot entirely, OneDrive content, or permanent data-security controls.  
**Last Updated:** August 2026

---

> **Quick path:** Scoping a new request → Part I. Already scoped and approved → Part III. Hit a licensing error → §4.

---

## PART I — DECIDE

### 1. Scope and intent

This guide covers restricting what Microsoft 365 Copilot can retrieve and cite from SharePoint Online, using **Restricted Content Discovery (RCD)**.

**Use this when a client asks for any of the following:**

- "Copilot shouldn't be able to see [site/department]"
- "We need HR/Legal/Finance out of Copilot before rollout"
- A temporary hold on specific content while a permissions review is completed

**Do not use this guide for:**

- Blocking Copilot entirely — that's a licensing action, not a SharePoint one
- Permanent data security controls — use sensitivity labels and Purview DLP instead
- OneDrive content — RCD does not apply to OneDrive

#### The conversation to have first

"Copilot shouldn't search SharePoint" is functionally close to "don't deploy Copilot." The SharePoint index is most of what Copilot grounds on. Before scoping work, pin down what the client actually means. Nine times out of ten it's one of:

| What they say | What they usually mean | Right control |
|---|---|---|
| "Copilot shouldn't read SharePoint" | Users shouldn't surface other teams' files | Fix permissions (DAG reports) |
| "Keep HR/Legal out of Copilot" | Genuinely site-scoped restriction | RCD — this guide |
| "Regulated content must stay out" | Content-following, durable control | Sensitivity labels + Purview |
| "We're not ready yet" | Time-boxed hold during review | RCD as a bridge, with an exit date |

Blanket RCD across a whole tenant strips the Copilot button and AI actions from every site. If the client just paid for Copilot seats, they will notice. Document the tradeoff in writing.

---

### 2. What RCD does — and doesn't

Confirm the control matches the requirement before scoping hours against it.

| Behavior | Effect |
|---|---|
| Copilot responses | Site content no longer surfaces or is cited |
| Org-wide search | Site content excluded |
| AI entry points | Copilot button, AI actions, Create-with-AI removed from the site |
| Recently-interacted files | **Verify in tenant** — sources conflict on whether content the user owns or recently touched still surfaces |
| Direct access | **Unchanged** — anyone who could open the file still can |
| Search index | **Content remains indexed** |
| eDiscovery / auto-labeling | **Unaffected** |
| Data-in-use | **Not blocked** — Copilot can still summarize an already-open document |
| OneDrive | **Out of scope** |

Microsoft positions RCD as a **temporary governance control**, not a permanent security boundary. Frame it that way with clients and set an exit date.

#### Gaps to disclose during scoping

Raise all four before the client signs, not after:

**New sites are not covered.** RCD has no inheritance — anything provisioned after your sweep comes back discoverable. Needs a scheduled runbook (Azure Automation or RMM) or a site-creation hook. Quote it as recurring work, not one-time.

**OneDrive is out of scope.** Copilot still grounds on users' own OneDrive content and recently-touched files. If the requirement is "Copilot returns nothing from user file storage," RCD does not get you there.

**Propagation is slow and uneven.** Microsoft documents that RCD is a site-level setting propagated to the search index, and that bulk changes queue in the ingestion pipeline and raise latency. No published SLA. Field reports suggest days, longer on very large sites — measure in the tenant rather than quoting a number.

**Data-in-use is unaffected.** An open document can still be summarized.

---

### 3. Alternatives worth proposing

If §2 shows RCD is a poor fit, or you want to position it as a bridge rather than a destination:

- **Sensitivity labels + Purview DLP for Copilot** — content-following, survives site moves, doesn't degrade Copilot globally. The durable answer for genuinely sensitive material.
- **Permissions remediation** — DAG reports, then fix the actual oversharing. Addresses root cause.
- **Sharing link defaults** — tenant and site-level default link type and expiration. Configurable without SAM, reduces future drift.
- **M365 Archive** — archived site content isn't available to Copilot and drops storage consumption. Good fit for stale sites.

---

## PART II — PLAN

### 4. Licensing gate — read this before quoting hours

RCD requires **SharePoint Advanced Management (SAM)**. SAM is granted when **at least one Microsoft 365 Copilot license is assigned to a user** in the tenant. That user does not need to be an admin.

**MSP note:** purchased-but-unassigned seats do not trigger the entitlement. You cannot pre-stage RCD before Copilot licenses land. If you try, every `Set-SPOSite` call fails with:

```text
You need a SharePoint Advanced Management license to perform this action.
```

The sequence is forced:

1. Client purchases Copilot, assigns **at least one seat**
2. Wait for SAM entitlement to provision (field estimate ~24h; not a documented SLA)
3. Configure RCD
4. Wait for index propagation (no published SLA; plan for days, longer on large sites)

**Rollout risk:** if seats go to the pilot group on day one, those users have full grounding while your restrictions are still propagating. Assign the first seat to an admin or service account, complete the RCD work, *then* release seats to end users. Build this into the project plan.

#### Verify entitlement

```powershell
Connect-MgGraph -Scopes "Organization.Read.All"
Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -like "*COPILOT*" } |
    Select-Object SkuPartNumber, ConsumedUnits, @{n='Total';e={$_.PrepaidUnits.Enabled}}
```

`ConsumedUnits` of 0 means no assigned seat and RCD will fail.

#### If SAM errors persist despite an assigned seat

1. Allow ~24h for entitlement propagation (undocumented; Microsoft describes SAM enablement as a gradually deploying code update)
2. Confirm the base SKU qualifies
3. `Update-Module Microsoft.Online.SharePoint.PowerShell` and reconnect
4. **[UNVERIFIED — single third-party source]** A `SharePoint Advanced Management Administrator` Entra role is reported to exist, separate from SharePoint Admin and not inherited by Global Admins, primarily gating file-level governance reports. Confirm it exists in the tenant before relying on it; cheap to assign and retry if so.

#### Full prerequisites

| Requirement | Detail |
|---|---|
| SharePoint Online Management Shell | Current version — `Update-Module Microsoft.Online.SharePoint.PowerShell` |
| Admin role | SharePoint Administrator or Global Administrator |
| Copilot license | At least one M365 Copilot seat **assigned** (verified above, not assumed) |
| Base SKU | A qualifying base SKU underneath the Copilot add-on |
| Smoke test | `Set-SPOSite` succeeds against one low-risk site |
| Client sign-off | Approved classification sheet (§5) |
| Change window | Accounts for multi-day index propagation |

---

### 5. Discovery and classification

This is where the real hours are, and it's the deliverable clients should sign.

```powershell
Connect-SPOService -Url https://<tenant>-admin.sharepoint.com

Get-SPOSite -Limit All |
    Select-Object Url, Title, Template, Owner, StorageUsageCurrent,
                  LastContentModifiedDate, SharingCapability,
                  RestrictContentOrgWideSearch |
    Export-Csv "C:\Temp\<client>-site-inventory.csv" -NoTypeInformation
```

Add a decision column per site: **Restrict / Allow / Review**. Get written client approval before applying anything.

**Signals that a site should be restricted:**

- Regulated or client-confidential material (PHI, PII, financials, legal hold)
- Broad "Everyone except external users" grants
- Active external sharing on internal-only content
- No identified owner
- Stale content that would pollute Copilot answers

**MSP note:** a permissions signal is available *without* SAM, which is useful during pre-sales before licenses land. PnP PowerShell or Graph will surface external sharing state, unique permission scopes, and broad grants across site collections. That covers most of what DAG reports give you, just less packaged.

---

## PART III — EXECUTE

### 6. Applying RCD

#### Single site

```powershell
Set-SPOSite -Identity https://<tenant>.sharepoint.com/sites/Finance `
            -RestrictContentOrgWideSearch $true
```

Also available in the SharePoint admin center: **Active sites > [site] > Settings > Restrict content from Microsoft 365 Copilot**.

#### From an approved CSV (preferred for client work)

Filter your classification sheet to `Decision = Restrict`, then:

```powershell
$targets = Import-Csv "C:\Temp\<client>-site-inventory.csv" |
           Where-Object { $_.Decision -eq 'Restrict' }

$log = foreach ($t in $targets) {
    try {
        Set-SPOSite -Identity $t.Url -RestrictContentOrgWideSearch $true -ErrorAction Stop
        [pscustomobject]@{ Url = $t.Url; Result = 'OK'; Detail = '' }
    } catch {
        [pscustomobject]@{ Url = $t.Url; Result = 'FAIL'; Detail = $_.Exception.Message }
    }
    Start-Sleep -Milliseconds 500   # throttling headroom
}

$log | Export-Csv "C:\Temp\<client>-rcd-apply-log.csv" -NoTypeInformation
$log | Group-Object Result | Select-Object Name, Count
```

Keep the apply log — it's your evidence artifact for the ticket and the client report.

#### Tenant-wide sweep

Only with explicit written client acknowledgment of the Copilot degradation (§1). Same loop, sourced from `Get-SPOSite -Limit All`, excluding system templates.

> **Validate this filter before trusting it.** The template list below is hand-built, not from Microsoft documentation, and `EHS` in particular is unconfirmed. Run `Get-SPOSite -Limit All | Group-Object Template` against the tenant first and adjust — a wrong pattern silently skips real sites.

```powershell
$sites = Get-SPOSite -Limit All | Where-Object {
    $_.Template -notmatch 'SPSMSITEHOST|APPCATALOG|SRCHCEN|POINTPUBLISHINGHUB|EHS' -and
    $_.RestrictContentOrgWideSearch -ne $true
}
```

#### Delegating to site owners

Lets owners self-manage with a justification prompt:

```powershell
Set-SPOTenant -DelegateRestrictedContentDiscoverabilityManagement $true
```

---

### 7. Validation

```powershell
# Per site
Get-SPOSite -Identity <site-url> | Select-Object Url, RestrictContentOrgWideSearch

# Everything currently restricted
Get-SPOSite -Limit All |
    Where-Object { $_.RestrictContentOrgWideSearch -eq $true } |
    Select-Object Url, Title

# Tenant report
Start-SPORestrictedContentDiscoverabilityReport
Get-SPORestrictedContentDiscoverabilityReport
```

**Functional test** (after propagation): have a licensed user with permission to a restricted site ask Copilot a question answerable only by content in that site. Expect no citation from it. Confirm they can still open the file directly.

---

### 8. Rollback

```powershell
Set-SPOSite -Identity <site-url> -RestrictContentOrgWideSearch $false
```

Reversal is subject to the same propagation delay as enablement. Content does not reappear in Copilot instantly.

---

### 9. Engagement checklist

- [ ] Requirement clarified against the §1 table; real need identified
- [ ] Control behavior and the four gaps (§2) disclosed in writing
- [ ] Alternatives (§3) presented where RCD is a poor fit
- [ ] Copilot licensing confirmed and at least one seat assigned
- [ ] SAM entitlement verified working (test cmdlet on one low-risk site)
- [ ] Site inventory exported and classified
- [ ] Client sign-off on the classification sheet
- [ ] First seat to admin/service account; end-user seats held until propagation completes
- [ ] RCD applied; apply log retained
- [ ] Validation report run and archived
- [ ] Functional test with a licensed user
- [ ] New-site coverage quoted as recurring work
- [ ] Exit date and review cadence agreed

---

## PART IV — REFERENCE

### 10. Knowledge Agent — related but separate

`KnowledgeAgentScope` controls the in-site **Knowledge Agent** (metadata suggestions, view generation, bulk column updates for site owners). It does **not** affect Copilot grounding. Turning it off will not satisfy a "keep content out of Copilot" requirement.

```powershell
# Check current state
Get-SPOTenant | Select-Object KnowledgeAgentScope, KnowledgeAgentSelectedSitesList

# Disable tenant-wide
Set-SPOTenant -KnowledgeAgentScope NoSites

# Selective (list-based scopes are capped — commonly reported as 100 sites; verify current limit)
Set-SPOTenant -KnowledgeAgentScope ExcludeSelectedSites
Set-SPOTenant -KnowledgeAgentSelectedSitesList @("<url1>","<url2>")
Set-SPOTenant -KnowledgeAgentSelectedSitesList @("<url3>") -KnowledgeAgentSelectedSitesListOperation Append
```

`NoSites` with an empty list is the default — it means Knowledge Agent was never enabled, not that someone disabled it.

Reasonable as defense-in-depth alongside RCD. Never as a substitute.

---

### 11. Deprecated — do not use

**Restricted SharePoint Search** (`Set-SPOTenant -RestrictedSearchMode Enabled`, the 100-site allow-list). Being retired; Microsoft directs new work to RCD. Reported dates vary across sources — new enablement blocked around **July 31, 2026**, with full retirement cited as **January 2027**. Confirm current status before touching an existing tenant. Either way, don't build new engagements on it.

**`Set-SPOSite -NoCrawl $true`.** De-indexes the site entirely, breaking in-site search and every index-dependent feature. Blunt instrument, bad trade.

---

## Sources

- Microsoft Learn: [Restrict discovery of SharePoint sites and content](https://learn.microsoft.com/en-us/sharepoint/restricted-content-discovery)
- Microsoft Learn: [SharePoint Advanced Management overview](https://learn.microsoft.com/en-us/sharepoint/advanced-management)
- Microsoft Learn: [Restricted SharePoint Search](https://learn.microsoft.com/en-us/sharepoint/restricted-sharepoint-search) — the deprecated control in §11
- Microsoft Learn: [Data access governance reports](https://learn.microsoft.com/en-us/sharepoint/data-access-governance-reports)
- Microsoft Learn: [`Set-SPOSite`](https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/set-sposite) and [`Set-SPOTenant`](https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/set-spotenant) — `RestrictContentOrgWideSearch`, `KnowledgeAgentScope`, `DelegateRestrictedContentDiscoverabilityManagement`
- Microsoft Learn: [Connect to SharePoint Online PowerShell](https://learn.microsoft.com/en-us/powershell/sharepoint/sharepoint-online/connect-sharepoint-online)
- Microsoft Learn: [Microsoft Purview data security and compliance protections for Copilot](https://learn.microsoft.com/en-us/purview/ai-microsoft-purview-considerations) — the durable alternative in §3
- Microsoft Learn: [Microsoft 365 Copilot data, privacy, and security](https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-privacy)
- Microsoft Learn: [External sharing overview](https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview)
- Microsoft Learn: [Overview of Microsoft 365 Archive](https://learn.microsoft.com/en-us/microsoft-365/archive/archive-overview)

Items marked **[UNVERIFIED]** or **Verify in tenant** in the body are field observations that are not backed by the Microsoft documentation above — confirm them in the tenant before relying on them with a client.
