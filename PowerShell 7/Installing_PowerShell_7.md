# Installing PowerShell 7

### Helpdesk Technician Reference

> **Applies to:** Windows 10/11, macOS  
> **Last updated:** May 2026

---

## Table of Contents

1. [Overview](#1-overview)
2. [Part 1 — Installing PowerShell 7 on Windows (winget)](#2-part-1--installing-powershell-7-on-windows-winget)
3. [Part 2 — Installing PowerShell 7 on macOS](#3-part-2--installing-powershell-7-on-macos)
4. [Verify the Installation](#4-verify-the-installation)
5. [Installing the Exchange Online PowerShell Module](#5-installing-the-exchange-online-powershell-module)
6. [Troubleshooting Common Issues](#6-troubleshooting-common-issues)

---

## 1. Overview

PowerShell 7 is the modern, cross-platform version of PowerShell built on .NET Core. It runs on Windows, macOS, and Linux. For managing Exchange Online, PowerShell 7 is the recommended version.

> **Terminology note:** You may see older documentation refer to "PowerShell Core" — this was the branding used for versions 6.x only. Starting with version 7, Microsoft dropped the "Core" label. It is simply called **PowerShell 7** (or just PowerShell).

**Why PowerShell 7 over Windows PowerShell 5.1?**

- Cross-platform — runs on Windows and macOS
- Actively maintained and updated by Microsoft
- Improved performance and new language features
- Required for some newer Microsoft 365 module features

> **Note:** Windows PowerShell 5.1 (built into Windows) and PowerShell 7 are separate installs and can coexist on the same machine. Installing PowerShell 7 does not remove or replace Windows PowerShell 5.1.

---

## 2. Part 1 — Installing PowerShell 7 on Windows (winget)

### What is winget?

**winget** is the Windows Package Manager, built into Windows 10 (version 1809 and later) and Windows 11. It allows you to install software from the command line, similar to how `apt` works on Linux.

### Prerequisites

- Windows 10 (version 1809 or later) or Windows 11
- winget is included by default on Windows 11 and most up-to-date Windows 10 installs
- An internet connection

### Step 1 — Verify winget is Installed

1. Open **Command Prompt** or **Windows PowerShell** (the built-in version).
2. Run the following command:

```
winget --version
```

3. If winget is installed, you will see a version number such as `v1.8.1911` or similar.
4. If you receive an error, install winget from the **Microsoft Store** by searching for **"App Installer"** and updating it.

### Step 2 — Install PowerShell 7 with winget

1. Open **Command Prompt** or **Windows PowerShell** as a regular user (no need for admin for winget).
2. Run the following command:

```powershell
winget install --id Microsoft.PowerShell --source winget
```

3. You may be prompted to agree to the source terms — type `Y` and press **Enter**.
4. winget will download and install PowerShell 7 automatically.
5. **You may see a UAC (User Account Control) prompt during installation — click Yes to allow it.** This is expected and required to complete the install.
6. When complete, you will see a message confirming the installation was successful.

> **Tip:** If you want to install a specific version, you can add the `--version` flag. For the latest stable release, the command above is all you need.

### Step 3 — Launch PowerShell 7 on Windows

After installation, you can open PowerShell 7 in several ways:

- **Start Menu** — Search for **PowerShell 7** or **pwsh**.
- **Run dialog** — Press `Win + R`, type `pwsh`, and press **Enter**.
- **Terminal** — If you have Windows Terminal installed, PowerShell 7 appears as a profile in the dropdown.
- **Command Prompt** — Type `pwsh` and press **Enter**.

### Keeping PowerShell 7 Up to Date on Windows

To upgrade PowerShell 7 to the latest version using winget, run:

```powershell
winget upgrade --id Microsoft.PowerShell --source winget
```

> Once installed, proceed to [Section 4 — Verify the Installation](#4-verify-the-installation) to confirm everything is working correctly.

---

## 3. Part 2 — Installing PowerShell 7 on macOS

### Prerequisites

- macOS 11 (Big Sur) or later is recommended
- **Homebrew** package manager installed (instructions below)
- An internet connection

### Step 1 — Install Homebrew (if not already installed)

Homebrew is the most popular package manager for macOS. If you already have Homebrew installed, skip to Step 2.

1. Open **Terminal** (Applications → Utilities → Terminal, or use Spotlight: `Cmd + Space`, type `Terminal`).
2. Run the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Follow the on-screen prompts. You may be asked for your macOS password.
4. **Apple Silicon (M1/M2/M3) Macs only:** After installation completes, Homebrew will display a message telling you to add it to your PATH. Run the following command in Terminal to do so:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

   To make this permanent, also add it to your shell profile:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
```

   Intel Macs do not require this step — Homebrew installs to `/usr/local/` which is already in the PATH.

5. When complete, verify Homebrew is installed by running:

```bash
brew --version
```

You should see output like `Homebrew 4.x.x`.

### Step 2 — Install PowerShell 7 with Homebrew

1. In **Terminal**, run the following command:

```bash
brew install --cask powershell
```

2. Homebrew will download and install PowerShell 7. This may take a few minutes.
3. When complete, you will see a success message in the terminal.

### Step 3 — Launch PowerShell 7 on macOS

After installation, open PowerShell 7 by running the following in Terminal:

```bash
pwsh
```

Your prompt will change to:

```
PS /Users/yourname>
```

This confirms PowerShell 7 is running. To exit PowerShell and return to the normal Terminal shell, type:

```powershell
exit
```

### Keeping PowerShell 7 Up to Date on macOS

To upgrade PowerShell 7 to the latest version using Homebrew, run:

```bash
brew upgrade --cask powershell
```

> Once installed, proceed to [Section 4 — Verify the Installation](#4-verify-the-installation) to confirm everything is working correctly.

---

## 4. Verify the Installation

After installing on either platform, confirm PowerShell 7 is working correctly by running the following inside a PowerShell 7 session:

```powershell
$PSVersionTable
```

You should see output similar to one of the following depending on your platform:

**On Windows:**
```
Name                           Value
----                           -----
PSVersion                      7.4.x
PSEdition                      Core
GitCommitId                    7.4.x
OS                             Microsoft Windows 10.0.xxxxx
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0, 5.0, 5.1.0, 6.0.0, 7.0.0}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

**On macOS:**
```
Name                           Value
----                           -----
PSVersion                      7.4.x
PSEdition                      Core
GitCommitId                    7.4.x
OS                             Darwin 23.x.x Darwin Kernel ...
Platform                       Unix
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0, 5.0, 5.1.0, 6.0.0, 7.0.0}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

Confirm that **PSEdition** shows `Core` and **PSVersion** starts with `7`.

---

## 5. Installing the Exchange Online PowerShell Module

Once PowerShell 7 is installed on either Windows or macOS, you can install the Exchange Online management module. This step is the same on both platforms.

### Install the Module

1. Open **PowerShell 7** (`pwsh`).
2. Run the following command:

```powershell
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
```

3. If prompted to install from an untrusted repository, type `Y` and press **Enter**.
4. The module will download and install.

### Connect to Exchange Online

> **Important:** You must have the **Exchange Administrator** or **Exchange Recipient Administrator** role assigned in Microsoft 365 to manage Exchange Online via PowerShell. A standard user account will receive an access denied error. Contact your Microsoft 365 administrator if you need this role assigned.

Once the module is installed, connect to Exchange Online with your admin UPN (replace `admin@contoso.com` with your own admin account):

```powershell
Connect-ExchangeOnline -UserPrincipalName admin@contoso.com
```

A browser window will open for you to sign in with your Microsoft 365 admin account (MFA included).

### Disconnect When Finished

```powershell
Disconnect-ExchangeOnline -Confirm:$false
```

> **Important:** Always disconnect your session when done. Leaving an active session open is a security risk.

### Keep the Module Up to Date

```powershell
Update-Module -Name ExchangeOnlineManagement
```

> **Note:** If `Install-Module` fails, your corporate network may be blocking access to the PowerShell Gallery (`powershellgallery.com`). Contact your network team to allow outbound HTTPS to `powershellgallery.com`, or request an offline/manual module installation from your IT team.

---

## 6. Troubleshooting Common Issues

### winget is not recognized (Windows)

**Symptom:** Running `winget` returns "command not found" or similar error.

**Fix:**
1. Open the **Microsoft Store**.
2. Search for **App Installer** and click **Update** (or **Install** if missing).
3. After updating, close and reopen your terminal and try `winget --version` again.

### UAC prompt is blocked or missing (Windows)

**Symptom:** The winget install appears to hang or fails silently.

**Fix:** Check whether your organization's Group Policy restricts UAC elevation for standard users. You may need to run the install from an account with local admin rights, or ask your IT admin to push PowerShell 7 via Intune or SCCM instead.

### Homebrew install fails on macOS

**Symptom:** The Homebrew install script errors out immediately.

**Fix:** Homebrew requires **Xcode Command Line Tools**. Install them by running:

```bash
xcode-select --install
```

Follow the on-screen prompt, wait for the install to complete, then retry the Homebrew install script.

### `brew` command not found after installing Homebrew (Apple Silicon)

**Symptom:** After installing Homebrew on an M1/M2/M3 Mac, running `brew` returns "command not found."

**Fix:** Homebrew on Apple Silicon installs to `/opt/homebrew/` which is not in the default PATH. Run:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

To make this permanent across all terminal sessions:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
```

### `Install-Module` fails — PSGallery not trusted

**Symptom:** Running `Install-Module` prompts "Are you sure you want to install from untrusted repository?" and you cannot accept.

**Fix:** Run the following to trust the PowerShell Gallery, then retry:

```powershell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
```

### `Connect-ExchangeOnline` returns Access Denied

**Symptom:** After connecting, cmdlets return permission errors or you cannot connect at all.

**Fix:** Your account does not have the required Exchange Online admin role. Ask your Microsoft 365 Global Administrator to assign you the **Exchange Administrator** or **Exchange Recipient Administrator** role in `entra.microsoft.com`.

---

*For additional help, visit [Microsoft Learn — Install PowerShell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) or [Homebrew Documentation](https://brew.sh).*
