# Contributing to the MSP Microsoft 365 Knowledge Base

This is a living, MSP-focused knowledge base. Every article is written for a **helpdesk technician who needs a working answer fast** — not for executives and not as a rewrite of Microsoft marketing. Each guide should come from a real problem and leave the next technician better off than a cold web search would.

> Knowledge hoarded is knowledge that decays. Knowledge shared compounds.

---

## Audience & tone

- Write for a competent technician under time pressure.
- Lead with **what to do**; explain *why* only where it prevents a mistake.
- Prefer concrete portal paths, exact cmdlets, and version numbers over vague guidance.
- Flag MSP realities: multi-tenant differences, licensing tiers, and the defaults you actually see in client tenants.

---

## Repository structure

- **One folder per Microsoft product / surface** — e.g. `Microsoft Entra`, `Microsoft Intune`, `Microsoft Defender`, `Microsoft Exchange Online`.
- **Every folder has a `README.md`** that acts as that folder's index:
  - Opens with `# <Folder Name>` and a one-line description of the folder's scope.
  - Lists each article as `### [Article Title](./url-encoded-filename.md)` followed by a summary paragraph.
- Put a new article in the folder matching its **primary** product. When a topic spans surfaces (e.g. SSPR touches Entra, Conditional Access, and Cloud Sync), file it where a technician would actually go to configure it, and cross-link from related articles.

---

## Adding or updating an article

1. Drop the draft in the local **`_temp/`** staging folder (local-only, never committed — see Git workflow).
2. Start from [`_templates/article-template.md`](./_templates/article-template.md).
3. Move the finished file into the correct product folder.
4. **Update that folder's `README.md`** — add a `### [Title](./file.md)` entry with a summary paragraph, matching the existing entries.
5. Commit and push (see below).

---

## Article conventions

- **Filenames:** Title Case with spaces, `.md` extension — e.g. `Microsoft SSPR Deployment Guide.md`. (A few older files use underscores; new files should use spaces for consistency.)
- **Metadata header:** start the article with bold key/value lines — **Applies to**, **Scope**, **Last Updated** — each ending in two trailing spaces so they render on separate lines.
- **Keep `Last Updated` current:** bump it whenever you revise an article. M365 changes constantly and readers trust the date to judge freshness.
- **Code blocks:** always fenced with a language tag (e.g. ` ```powershell `).
- **Portal paths:** put navigation in **bold**, e.g. **Entra ID > Password reset > Properties**.
- **Sources:** end with a `## Sources` section. Prefer `learn.microsoft.com` URLs over raw `github.com/MicrosoftDocs` links; credit community/MVP sources by name.

---

## Git workflow

- **All commits and pushes use the `anthonyjohnsonga` GitHub account** — the sole author and contributor on this repository.
- **Do not add `Co-Authored-By` trailers** of any kind to commits on this repo.
- The local working copy is a clone of `anthonyjohnsonga/MSP-Microsoft-365-KB` tracking the `main` branch; pushing goes straight to `main`.
- **`_temp/`** (local staging) and **`.claude/`** are gitignored and must never be pushed.
