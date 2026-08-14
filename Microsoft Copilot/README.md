# Microsoft Copilot

This folder contains reference guides for Microsoft 365 Copilot in an MSP-managed tenant — readiness and rollout work, what Copilot grounds on, and the controls that govern which content it can retrieve and cite.

---

### [Controlling Copilot Access to SharePoint Content](./Microsoft%20Copilot%20SharePoint%20Grounding%20Control%20Guide.md)

A reusable engagement guide for restricting what Microsoft 365 Copilot can retrieve and cite from SharePoint Online using **Restricted Content Discovery (RCD)**. Structured as four parts — Decide, Plan, Execute, Reference — so it works both as pre-sales scoping material and as a runbook once the work is approved. Opens with the conversation to have before quoting hours (a table mapping what clients say to what they actually mean and the right control for each), then a behavior matrix showing exactly what RCD does and doesn't block: content stays indexed, direct access is unchanged, eDiscovery is unaffected, and an already-open document can still be summarized. Documents the four gaps to disclose in writing before a client signs — no inheritance for new sites, OneDrive out of scope, unpredictable multi-day index propagation, and data-in-use.

The licensing gate gets its own section because it forces the project sequence: RCD requires SharePoint Advanced Management, which is only entitled once **at least one Copilot seat is actually assigned** — purchased-but-unassigned seats fail with `You need a SharePoint Advanced Management license to perform this action`. Includes a Graph check for `ConsumedUnits`, the fix path when SAM errors persist, and the rollout ordering that keeps end users from getting full grounding while restrictions are still propagating. Continues through site inventory and Restrict/Allow/Review classification, applying RCD per-site and from an approved CSV with a retained apply log, the tenant-wide sweep and its unverified template filter, owner delegation, validation cmdlets plus a functional Copilot test, and rollback. Ends with an engagement checklist, the separate `KnowledgeAgentScope` control (related but not a substitute), and the deprecated approaches to avoid — Restricted SharePoint Search and `-NoCrawl`.

---

## Related guides in other folders

- [Microsoft Purview DLP — External Sharing Alert](../Microsoft%20Purview/Microsoft%20Purview%20DLP%20External%20Sharing%20Alert%20Policy%20Creation.md) — sensitivity labels and Purview DLP are the durable alternative to RCD for genuinely sensitive content.
- [Microsoft OneDrive Sync Troubleshooting](../Microsoft%20OneDrive/Microsoft%20OneDrive%20Sync%20Troubleshooting.md) — RCD does not apply to OneDrive, which remains a Copilot grounding source.
