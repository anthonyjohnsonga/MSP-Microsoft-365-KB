# Microsoft Purview DLP — SharePoint/OneDrive External Sharing Alert

**Applies to:** Microsoft 365 Business Premium, E3/E5 (Purview DLP for SharePoint/OneDrive is included — no add-on)  
**Scope:** Build a monitor-only DLP policy that alerts admins whenever a user shares SharePoint/OneDrive content externally, regardless of permission path; runs in simulation mode so nothing is blocked.  
**Last Updated:** June 2026

---

## Overview

Alert administrators every time any user shares SharePoint or OneDrive content with someone outside the organization — regardless of which permission path (Guest Inviter role, Member invite setting, etc.) the user took to do it. Monitor-only by design: runs in **simulation mode** so nothing is actually blocked for end users.

**License requirement:** Included with Microsoft 365 Business Premium — no add-on required. Microsoft Purview DLP for Exchange Online, SharePoint Online, and OneDrive for Business is included with Business Premium, E3/E5, and equivalent plans.

---

## Step 1: Start the policy

1. **Microsoft Purview portal** → **Data loss prevention** → **Policies** → **Create policy**
2. Select **Enterprise applications & devices** (not "Inline web traffic" — that's for the Edge for Business/SASE scenario)
3. **Categories** → **Custom**
4. **Regulations** → **Custom policy**
5. Select **Next**

> Use a unique policy name each time you build one of these. Policies can't be renamed after creation.

6. Enter a **Name** and **Description** → **Next**
7. **Assign admin units** → accept default **Full directory** → **Next**
8. **Locations** → select only **SharePoint sites** and **OneDrive accounts** — deselect everything else (Exchange, Teams, Power BI, etc.) → **Next**
9. On **Define policy settings**, leave **Create or customize advanced DLP rules** selected → **Next**

---

## Step 2: Build the rule — do all of this before saving

> Building the condition, action, notification, and incident report together in a single pass avoids a cascade of validation errors (see Known Errors below).

1. **+ Create rule**
2. Enter a **Name** and **Description** for the rule (do this immediately — a blank Name field has caused validation failures here before)

3. **Conditions** → **+ Add condition** → **Content is shared from Microsoft 365** → select **with people outside my organization**

4. **Actions** → **+ Add an action** → **Restrict access or encrypt the content in Microsoft 365 locations** → **Block only people outside your organization**

> This pairing (condition + action) is the exact combination documented by Microsoft for this scenario. Leaving Actions empty and relying only on Incident reports has reliably caused a "rule must contain one or more of these conditions" error for SharePoint/OneDrive-scoped rules — adding this action resolved it.

5. **User notifications** → toggle **On** → select **Notify users in Office 365 services with a policy tip** → select **Notify the user who sent, shared, or last modified the content**

> Required once a Restrict access/Block action is added — Microsoft will reject the rule with a "Missing parameter: NotifyUser" error otherwise.

6. **User overrides** → make sure **Allow override from M365 services** is **NOT** checked

7. **Incident reports**:
   - Severity: **High**
   - **Send an alert to admins when a rule match occurs** → **On**
   - **Send email alerts to these people** → add the recipient(s) who should be notified
   - Leave **Use email incident reports to notify you when a policy match occurs** off (optional, separate aggregated-report feature)

8. **Save**

---

## Step 3: Finish and deploy safely

1. Back on **Advanced DLP rules**, confirm there is exactly **1 item**, and that Conditions, Actions, User notifications, and Incident reports all show correctly in the summary
2. **Next** → **Policy mode** → select **Run the policy in simulation mode**

> Simulation mode means the Block action is never actually enforced — no real user is blocked. It only logs the match and fires the alert/incident report, which is exactly the monitor-only behavior intended here. This is safe to leave running long-term rather than treating it only as a temporary test phase.

3. **Next** → **Submit**

---

## Known errors and fixes (encountered building this policy type)

| Error | Cause | Fix |
|---|---|---|
| `Every rule must contain one or more of these conditions: 'ContentContainsSensitiveInformation,...'` | Rule's Name field was blank, OR the rule had no real Action attached (Incident report alerts alone don't satisfy this for SharePoint/OneDrive) | Fill in the rule Name; add the **Restrict access → Block only people outside your organization** action alongside the condition |
| `Missing parameter: 'NotifyUser'... Use of 'BlockAccessScope PerUser' requires -BlockAccess $true -AccessScope NotInOrganization -NotifyUser -NotifyAllowOverride parameters` | Added the Block action without configuring User notifications | Turn on User notifications → Notify the user who sent/shared/last modified the content; leave Allow override unchecked |
| Same conditions error recurring after fixing Name/NotifyUser and re-adding the condition fresh | Corrupted rule/policy draft state, likely from the original failed save | Discard the entire policy and rebuild from a fresh **Create policy** wizard, doing all rule configuration (condition + action + notifications + incident report) in one pass before the first save |

---

## Verification after deployment

- Confirm the policy shows as **On** (in simulation) under Data loss prevention → Policies
- Wait a few days, then check **Alerts** (Defender/Purview portal) for matches generated by real external shares
- Once confident it's catching the right activity with no false positives, decide whether to leave it permanently in simulation mode (alert-only) or turn it fully on (alert + actual block)
