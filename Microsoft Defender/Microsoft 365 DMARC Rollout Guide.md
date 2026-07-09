# DMARC Rollout Guide: Moving from `p=none` to `p=reject`

**Applies to:** Microsoft 365 tenants with custom domains (all license tiers)  
**Scope:** Safely move a domain from DMARC monitoring mode (`p=none`) to enforcement (`p=quarantine`) and finally full rejection (`p=reject`) without breaking legitimate mail flow  
**Last Updated:** July 2026

---

## 1. Overview

A DMARC record with `p=none` is useful during the initial discovery and tuning phase, but it should not be treated as the final security state. `p=none` provides visibility into authentication results but does not instruct receiving mail systems to quarantine or reject messages that fail DMARC.

The recommended target state for an active sending domain is typically:

```txt
v=DMARC1; p=reject; pct=100; rua=mailto:dmarc-reports@example.com
```

The recommended rollout path is:

```text
No DMARC or p=none → p=none with reporting → p=quarantine → p=reject
```

For domains that do not send mail, the recommended posture is usually immediate enforcement:

```txt
v=DMARC1; p=reject
```

Microsoft recommends a gradual approach where administrators start with `p=none`, monitor DMARC results, then move to `p=quarantine`, and finally to `p=reject`. Microsoft also states that the goal is to reach `p=reject` for custom domains and subdomains, while testing along the way to avoid rejected legitimate email.

---

## 2. What DMARC Does

DMARC stands for **Domain-based Message Authentication, Reporting, and Conformance**.

DMARC builds on SPF and DKIM and checks whether the domain used for authentication aligns with the visible **From** domain that the user sees in their mail client.

A message passes DMARC when at least one of the following is true:

1. SPF passes and the SPF-authenticated domain aligns with the visible From domain.
2. DKIM passes and the DKIM signing domain aligns with the visible From domain.

DMARC also lets the domain owner tell receiving mail systems what to do when mail fails DMARC:

| DMARC Policy | Meaning | Typical Result |
|---|---|---|
| `p=none` | Monitor only | No DMARC-specific enforcement action |
| `p=quarantine` | Treat failing mail as suspicious | Junk, spam, quarantine, or marked delivery depending on receiver |
| `p=reject` | Reject failing mail | Usually rejected during SMTP or otherwise blocked by the receiver |

Important: DMARC is not a full anti-spam solution. It protects against unauthorized use of your domain in the visible From address. Receiving systems may still apply their own filtering even if DMARC passes.

---

## 3. Key Terms

### SPF

**Sender Policy Framework** identifies which mail servers are authorized to send mail for a domain.

Example:

```txt
v=spf1 include:spf.protection.outlook.com -all
```

SPF can fail in forwarding scenarios because the forwarding server may not be listed in the sender domain's SPF record.

### DKIM

**DomainKeys Identified Mail** uses a cryptographic signature to prove that a message was authorized by the signing domain and was not modified after signing.

For Microsoft 365, DKIM should be enabled for each custom domain that sends mail.

### DMARC Alignment

DMARC does not only care whether SPF or DKIM passed. It also checks whether the authenticated domain aligns with the visible From domain.

Example:

```text
Visible From domain: example.com
DKIM signing domain: example.com
Result: DKIM aligned
```

Example:

```text
Visible From domain: example.com
SPF Mail From domain: marketing-vendor.com
Result: SPF may pass, but SPF is not aligned with example.com
```

### Relaxed vs. Strict Alignment

DMARC supports relaxed and strict alignment for SPF and DKIM.

| Tag | Relaxed | Strict |
|---|---|---|
| `aspf` | `aspf=r` allows subdomain alignment | `aspf=s` requires exact SPF domain match |
| `adkim` | `adkim=r` allows subdomain alignment | `adkim=s` requires exact DKIM domain match |

If not specified, both default to relaxed alignment.

For most organizations, relaxed alignment is a safer starting point:

```txt
adkim=r; aspf=r
```

Strict alignment can be considered after the organization has a mature understanding of all sending sources.

---

## 4. Recommended Rollout Timeline

There is no universal fixed timeline because volume and complexity vary by organization. A small domain with only Microsoft 365 may move quickly. A domain with marketing platforms, CRMs, billing systems, copiers, websites, and third-party senders should move more slowly.

A practical MSP-friendly rollout timeline:

| Phase | Policy | Typical Duration | Purpose |
|---|---:|---:|---|
| Phase 0 | No change | 1–3 days | Inventory DNS, mail flow, and senders |
| Phase 1 | `p=none` | 2–4 weeks | Collect reports and identify legitimate senders |
| Phase 2 | `p=quarantine; pct=25` | 1–2 weeks | Start limited enforcement |
| Phase 3 | `p=quarantine; pct=50` | 1–2 weeks | Increase enforcement |
| Phase 4 | `p=quarantine; pct=100` | 1–2 weeks | Full quarantine enforcement |
| Phase 5 | `p=reject; pct=25` | 1–2 weeks | Start limited rejection |
| Phase 6 | `p=reject; pct=50` | 1–2 weeks | Increase rejection |
| Phase 7 | `p=reject; pct=100` | Ongoing | Final target state |

Microsoft documentation gives example `pct=` increments of 10, 25, 50, 75, and 100. The exact increments should be based on risk tolerance and the quality of the DMARC data.

---

## 5. Understanding the `pct=` Tag

The `pct=` tag means **percentage**. It tells receiving mail systems what percentage of mail should be subject to the requested DMARC enforcement policy.

Example:

```txt
v=DMARC1; p=quarantine; pct=25; rua=mailto:dmarc-reports@example.com
```

This means:

- DMARC reporting is still active for the domain.
- The domain owner is asking receivers to apply the `quarantine` policy to approximately 25% of messages that fail DMARC.
- The remaining failing messages are not supposed to receive the full requested DMARC enforcement action from this policy, although the receiving system may still apply its own spam, phishing, or security filtering.

Example:

```txt
v=DMARC1; p=reject; pct=50; rua=mailto:dmarc-reports@example.com
```

This means:

- The domain owner is asking receivers to apply the `reject` policy to approximately 50% of messages that fail DMARC.
- This is commonly used as a safer step between `p=quarantine` and full `p=reject` enforcement.

### Important Facts About `pct=`

- `pct=` accepts values from `0` to `100`.
- If `pct=` is omitted, the default is `pct=100`.
- `pct=100` means the requested DMARC policy applies fully.
- `pct=` is most useful with `p=quarantine` and `p=reject`.
- `pct=` does **not** make `p=none` an enforcement policy. A record such as `p=none; pct=100` is still monitoring-only.
- `pct=` is a request to receiving mail systems. Receivers are responsible for their own final handling and may apply local security policy.
- `pct=` should not be treated as an exact message-by-message guarantee. It is best understood as a staged rollout control for enforcement.

### Recommended Use During Rollout

Use `pct=` to reduce risk while moving into enforcement:

```text
p=none → p=quarantine; pct=25 → p=quarantine; pct=50 → p=quarantine; pct=100 → p=reject; pct=25 → p=reject; pct=50 → p=reject; pct=100
```

A conservative rollout may use smaller increments:

```text
pct=10 → pct=25 → pct=50 → pct=75 → pct=100
```

A simpler domain with only Microsoft 365 sending may be able to move faster. A complex domain with many vendors should move slower and review DMARC aggregate reports between each increase.

### Common Misunderstanding

`pct=25` does **not** mean that 25% of all email from the domain will be blocked or quarantined. It means the DMARC policy is being applied to a percentage of the messages that are subject to DMARC policy evaluation, with the practical impact being on messages that fail DMARC.

Legitimate messages that pass aligned SPF or aligned DKIM should not be blocked because of DMARC enforcement.

---

## 6. Pre-Change Checklist

Before changing DMARC, complete the following:

### DNS and Authentication

- [ ] Confirm the domain has exactly one SPF TXT record.
- [ ] Confirm SPF includes all authorized sending systems.
- [ ] Confirm SPF does not exceed the 10 DNS lookup limit.
- [ ] Confirm Microsoft 365 DKIM is enabled for the custom domain.
- [ ] Confirm third-party vendors are using aligned DKIM where possible.
- [ ] Confirm there is only one DMARC TXT record at `_dmarc.domain.com`.
- [ ] Confirm the current DMARC record syntax is valid.

### Sender Inventory

Identify every platform that sends email using the domain in the visible From address.

Common sources include:

- Microsoft 365 / Exchange Online
- Website contact forms
- WordPress SMTP plugins
- CRM platforms
- Marketing platforms
- Accounting systems
- Payroll systems
- Ticketing/helpdesk platforms
- Electronic signature platforms
- Backup systems and monitoring tools
- Scanners and copiers
- Line-of-business applications
- E-commerce systems
- HR platforms
- Payment systems
- Client portals
- Cloud-hosted applications

### Business Validation

- [ ] Identify business-critical mail streams.
- [ ] Identify high-volume mail streams.
- [ ] Identify systems that send as `@domain.com` but are hosted outside Microsoft 365.
- [ ] Identify any systems that cannot support DKIM alignment.
- [ ] Identify who owns each third-party platform.
- [ ] Identify a change window for policy changes.
- [ ] Identify a rollback owner.

---

## 7. Phase 1: Start or Correct DMARC Monitoring with `p=none`

Use `p=none` to collect reports and understand who is sending as the domain.

Example record:

```txt
Host/Name: _dmarc
Type: TXT
Value: v=DMARC1; p=none; pct=100; rua=mailto:dmarc-reports@example.com
TTL: 3600
```

Optional record with relaxed alignment explicitly stated:

```txt
v=DMARC1; p=none; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### Notes

- `p=none` does not enforce DMARC. It is for monitoring and tuning.
- `rua=` enables aggregate reports.
- Use a dedicated mailbox, shared mailbox, distribution group, or DMARC reporting service for aggregate reports.
- DMARC aggregate reports are XML and are difficult to review manually at scale. A reporting tool is strongly recommended.
- Avoid using a normal user mailbox for DMARC reports.
- `ruf=` forensic/failure reports are optional and not consistently supported by receivers. Microsoft 365 does not send DMARC forensic reports even when a valid `ruf=` address exists in the sender domain's DMARC record.

### What to Review During `p=none`

For each source shown in reports:

- Source IP
- Sending organization
- Header From domain
- SPF result
- SPF alignment result
- DKIM result
- DKIM alignment result
- Message count
- Whether the source is legitimate
- Whether the source is business critical

### Exit Criteria for Phase 1

Do not move to quarantine until:

- All known legitimate senders are identified.
- Microsoft 365 mail passes SPF and/or DKIM alignment.
- Important third-party platforms pass aligned DKIM or aligned SPF.
- Unknown sources have been reviewed.
- Business-critical mail streams have been tested.
- The organization understands the impact of quarantine enforcement.

---

## 8. Fixing Common Issues Before Enforcement

### Issue: Microsoft 365 Mail Fails DKIM

Action:

- Enable DKIM for the custom domain in Microsoft 365 Defender or Exchange Online.
- Confirm the required CNAME records are present in public DNS.
- Send a test message and review the message headers.

### Issue: Third-Party Vendor Passes SPF but Not DMARC

This often happens when the vendor authenticates using its own bounce/envelope domain instead of your domain.

Action:

- Ask the vendor to enable custom DKIM for your domain.
- Ask the vendor whether it supports a custom return-path/bounce domain.
- Prefer DKIM alignment over SPF alignment when possible.

### Issue: Website Forms Send Directly from Web Server

Action:

- Route website mail through an authenticated SMTP service.
- Use Microsoft 365 SMTP relay only where appropriate and supported.
- Configure DKIM for the sending service if available.
- Avoid unauthenticated PHP mail using the domain as the From address.

### Issue: Copier or Scanner Sends as the Domain

Action:

- Use authenticated SMTP where possible.
- Use Microsoft 365 SMTP AUTH only where allowed and appropriate.
- Consider SMTP relay through a properly authorized connector or relay service.
- Use a dedicated scanner address such as `scanner@domain.com`.
- Confirm SPF and/or DKIM alignment.

### Issue: Forwarding Breaks SPF

Forwarding commonly breaks SPF because the forwarding server is not authorized in the original sender's SPF record.

Action:

- Rely on DKIM alignment where possible.
- For inbound mail in Microsoft 365, consider ARC/trusted ARC sealers for known legitimate forwarding scenarios.
- Avoid broad allow rules that bypass security filtering.

### Issue: SPF Has Too Many Lookups

SPF evaluation has a DNS lookup limit. Too many `include`, `a`, `mx`, `exists`, or `redirect` mechanisms can cause SPF permerror.

Action:

- Remove unused vendors.
- Avoid adding vendors that are not sending as the domain.
- Prefer DKIM alignment for vendors when possible.
- Do not flatten SPF unless there is a process to maintain it.

---

## 9. Phase 2: Move to Quarantine

After legitimate senders are passing DMARC, move from monitoring to limited enforcement.

Recommended first quarantine record:

```txt
v=DMARC1; p=quarantine; pct=25; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

Then increase gradually:

```txt
v=DMARC1; p=quarantine; pct=50; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

```txt
v=DMARC1; p=quarantine; pct=75; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

```txt
v=DMARC1; p=quarantine; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### What Quarantine Means

A `p=quarantine` policy tells receiving systems that messages failing DMARC should be treated as suspicious. Depending on the receiver, these messages may be sent to Junk, placed in quarantine, tagged, or handled by local policy.

### Monitoring During Quarantine

Review:

- Any increase in user reports of missing mail
- DMARC report failures from known vendors
- Microsoft 365 message trace for outbound failures
- Vendor bounce logs
- Helpdesk tickets related to missing external mail
- High-volume sources that still fail alignment

### Exit Criteria for Quarantine

Do not move to reject until:

- `p=quarantine; pct=100` has been stable.
- No business-critical senders are failing DMARC unexpectedly.
- Known vendor issues are fixed or documented.
- Leadership or the business owner accepts the remaining risk.
- A rollback plan exists.

---

## 10. Phase 3: Move to Reject

After quarantine is stable, move to limited rejection.

Recommended first reject record:

```txt
v=DMARC1; p=reject; pct=25; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

Then increase gradually:

```txt
v=DMARC1; p=reject; pct=50; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

```txt
v=DMARC1; p=reject; pct=75; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

Final target:

```txt
v=DMARC1; p=reject; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

Because `pct=100` is the default when `pct=` is omitted, this is also valid:

```txt
v=DMARC1; p=reject; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### What Reject Means

A `p=reject` policy tells receiving systems that messages failing DMARC should be rejected. In Microsoft 365 inbound handling, Microsoft documents `p=reject` as rejected during SMTP with `550 5.7.1` when the DMARC policy is honored.

### Final-State Monitoring

After moving to `p=reject`, continue monitoring:

- DMARC aggregate reports
- Helpdesk tickets
- External bounce messages
- Vendor delivery dashboards
- Microsoft 365 message trace
- New applications or vendors added by business units

DMARC is not a one-time configuration. It must be maintained as mail systems change.

---

## 11. Subdomain Strategy

DMARC supports a subdomain policy using the `sp=` tag.

Example:

```txt
v=DMARC1; p=reject; sp=reject; rua=mailto:dmarc-reports@example.com
```

### Recommended Approach

- Start with lower-volume or simpler subdomains first.
- Save the parent domain for later if it has many sending sources.
- Use `sp=reject` when subdomains should inherit strong enforcement.
- Create separate DMARC records for subdomains that send mail differently.

Example for a marketing subdomain:

```txt
Host/Name: _dmarc.marketing
Value: v=DMARC1; p=quarantine; pct=50; rua=mailto:dmarc-reports@example.com
```

Example for the parent domain:

```txt
Host/Name: _dmarc
Value: v=DMARC1; p=reject; sp=reject; rua=mailto:dmarc-reports@example.com
```

---

## 12. Non-Sending Domains

Domains that do not send email should still have SPF, DKIM/DMARC considerations, and MX posture reviewed.

For a domain that should never send email, use a deny-all SPF record:

```txt
v=spf1 -all
```

Use DMARC reject:

```txt
Host/Name: _dmarc
Type: TXT
Value: v=DMARC1; p=reject
```

If the domain has subdomains that also should not send email:

```txt
v=DMARC1; p=reject; sp=reject
```

Important: Do not publish these records until you confirm the domain and its subdomains are not used for legitimate mail.

---

## 13. Microsoft 365-Specific Guidance

### Enable DKIM for Every Sending Custom Domain

In Microsoft 365, DKIM should be enabled for each custom domain that sends email. This helps mail pass DMARC even when SPF alignment fails because of forwarding or third-party routing.

### Watch the High-Risk Delivery Pool

Microsoft documents that outbound mail from Microsoft 365 domains that fail DMARC checks at the destination service is routed through the high-risk delivery pool when the domain's DMARC policy is `p=reject` or `p=quarantine`. Microsoft states there is no override for that behavior.

### Inbound DMARC Handling

For inbound messages into Microsoft 365, DMARC handling depends on Defender/EOP features, including spoof intelligence and whether the tenant honors the sender's DMARC policy.

### Forensic Reports

Microsoft 365 does not send DMARC forensic/failure reports, even if the source domain publishes a valid `ruf=` address.

---

## 14. Change Control Template

### Change Title

Move DMARC policy for `example.com` from `p=none` to `p=quarantine` / `p=reject`.

### Business Reason

Improve protection against domain spoofing and reduce the risk of phishing, business email compromise, and unauthorized use of the organization's domain in the visible From address.

### Current State

```txt
v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com
```

### Proposed State

```txt
v=DMARC1; p=quarantine; pct=25; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

or

```txt
v=DMARC1; p=reject; pct=25; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### Pre-Change Validation

- [ ] SPF validated.
- [ ] DKIM enabled and tested.
- [ ] DMARC reports reviewed.
- [ ] Major third-party senders identified.
- [ ] High-risk failures remediated.
- [ ] Business owner approval obtained.
- [ ] Rollback record prepared.

### Implementation Steps

1. Export or document the current DNS record.
2. Lower TTL ahead of change if needed.
3. Update TXT record at `_dmarc.example.com`.
4. Validate public DNS resolution.
5. Send test messages from Microsoft 365 and known third-party systems.
6. Review message headers for DMARC pass.
7. Monitor DMARC reports and message traces.
8. Document any issues and remediation.

### Rollback Plan

If legitimate business mail is impacted, revert to the previous DMARC record or reduce `pct=`.

Rollback example:

```txt
v=DMARC1; p=none; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

Less aggressive rollback example:

```txt
v=DMARC1; p=quarantine; pct=25; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

---

## 15. Testing Commands

### Windows PowerShell

```powershell
Resolve-DnsName -Type TXT _dmarc.example.com
Resolve-DnsName -Type TXT example.com
```

### nslookup

```cmd
nslookup -type=txt _dmarc.example.com
nslookup -type=txt example.com
```

### dig

```bash
dig TXT _dmarc.example.com +short
dig TXT example.com +short
```

### Message Header Items to Review

Look for:

```text
Authentication-Results:
spf=pass or spf=fail
dkim=pass or dkim=fail
dmarc=pass or dmarc=fail
header.from=example.com
```

For Microsoft 365, also review:

```text
compauth=pass
compauth=fail
dmarc=fail action=none
dmarc=fail action=quarantine
dmarc=fail action=oreject
```

---

## 16. Recommended Customer-Facing Language

Use this language when explaining the change to a client:

> DMARC helps protect your domain from being used in spoofed email. Your current `p=none` policy is useful for visibility, but it does not tell receiving mail systems to block or quarantine messages that fail authentication. Our recommendation is to use `p=none` only during the monitoring phase, fix any legitimate senders that fail DMARC, then gradually move to `p=quarantine` and finally `p=reject`. The target state is to prevent unauthorized systems from sending email that appears to come from your domain while avoiding disruption to legitimate mail flow.

---

## 17. MSP Operational Notes

### Do Not Rush to Reject Without Data

Moving directly from `p=none` to `p=reject` can break mail from legitimate third-party platforms if they are not aligned. The risk is highest for organizations with many unmanaged SaaS platforms.

### Do Not Leave `p=none` Forever

Leaving `p=none` indefinitely provides visibility but not enforcement. It does not stop spoofed messages from using the domain in the visible From address.

### Prefer Vendor DKIM Alignment

For third-party senders, the cleanest long-term fix is usually vendor-provided DKIM signing using the client's domain.

### Keep a Sender Register

Maintain a simple table like this:

| Sender | Owner | Purpose | SPF | DKIM | DMARC Pass | Notes |
|---|---|---|---|---|---|---|
| Microsoft 365 | IT | User mail | Pass | Pass | Pass | Primary mail system |
| Website | Marketing | Contact forms | Pass | Needs review | Partial | Move to authenticated SMTP |
| CRM | Sales | Campaigns | Pass | Pass | Pass | Vendor DKIM enabled |

### Recheck After Business Changes

Recheck DMARC when:

- A new marketing platform is added
- A new website launches
- A new ticketing system is implemented
- A domain is added to Microsoft 365
- DNS is migrated
- A merger/acquisition occurs
- A client starts using a new billing or HR platform

---

## 18. Example Records

### Monitoring Only

```txt
v=DMARC1; p=none; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### Limited Quarantine

```txt
v=DMARC1; p=quarantine; pct=25; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### Full Quarantine

```txt
v=DMARC1; p=quarantine; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### Limited Reject

```txt
v=DMARC1; p=reject; pct=25; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### Full Reject

```txt
v=DMARC1; p=reject; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### Full Reject with Subdomain Enforcement

```txt
v=DMARC1; p=reject; sp=reject; pct=100; rua=mailto:dmarc-reports@example.com; adkim=r; aspf=r
```

### Non-Sending Domain

```txt
v=DMARC1; p=reject; sp=reject
```

```txt
v=spf1 -all
```

---

## 19. Decision Matrix

| Situation | Recommended Action |
|---|---|
| No DMARC record exists | Publish `p=none` with `rua=` and begin monitoring |
| Domain has `p=none` for years | Review reports, fix senders, move to quarantine |
| All legitimate senders pass DMARC | Move toward `p=reject` gradually |
| Unknown high-volume sender appears | Investigate before increasing enforcement |
| Third-party sender fails alignment | Enable vendor DKIM or custom return-path if available |
| Domain does not send mail | Use `p=reject`, usually with `sp=reject`, after confirming no legitimate sending |
| Business-critical vendor cannot align | Risk-accept temporarily, use subdomain strategy, or change sender domain |
| Mail breaks after enforcement | Lower `pct=`, revert to quarantine/none, or fix authentication at source |

---

## 20. Risks and Mitigations

| Risk | Cause | Mitigation |
|---|---|---|
| Legitimate mail rejected | Vendor not aligned | Enable DKIM/custom domain with vendor before reject |
| Reports are unreadable | Aggregate XML is noisy | Use a DMARC reporting platform |
| SPF permerror | Too many DNS lookups | Remove unused includes, prefer DKIM |
| Forwarded mail fails SPF | Forwarder not in SPF | Use DKIM/ARC where possible |
| Business units add senders without IT | Shadow IT | Maintain sender register and require review before new tools send as domain |
| Overly broad allows | Quick workaround | Use temporary, specific exceptions only |

---

## 21. Sources

- Microsoft Learn — Set up DMARC to validate the From address domain for cloud senders: https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dmarc-configure
- RFC 7489 — Domain-based Message Authentication, Reporting, and Conformance: https://datatracker.ietf.org/doc/html/rfc7489
- Google Workspace Admin Help — Set up DMARC: https://knowledge.workspace.google.com/admin/security/set-up-dmarc
- Gmail Help — Email sender guidelines: https://support.google.com/mail/answer/81126
- Related guide in this KB: [Microsoft 365 Display Name Spoofing Guide](./Microsoft%20365%20Display%20Name%20Spoofing%20Guide.md) — display name spoofing passes DMARC for the attacker's own domain; that guide covers the layered defenses beyond email authentication

---

## 22. Summary

The best-practice approach is not simply to publish a DMARC record. The best practice is to operationalize DMARC:

1. Identify all legitimate senders.
2. Ensure SPF and/or DKIM alignment.
3. Start with `p=none` for reporting.
4. Move gradually to `p=quarantine`.
5. Move gradually to `p=reject`.
6. Continue monitoring after enforcement.

`p=none` is a valid temporary monitoring policy. It is not a strong final security posture. For most active business domains, the mature target state is `p=reject` with ongoing monitoring and sender governance.
