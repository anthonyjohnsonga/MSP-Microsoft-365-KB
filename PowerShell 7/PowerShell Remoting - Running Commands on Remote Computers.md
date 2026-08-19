# PowerShell Remoting — Running Commands on Remote Computers

**Applies to:** Windows PowerShell 5.1 and PowerShell 7.x on domain-joined or workgroup Windows endpoints  
**Scope:** The three ways to run PowerShell against a remote machine, when to use each, and the WinRM/firewall configuration they depend on. Covers WSMan remoting; SSH-based remoting and JEA are noted but not detailed.  
**Last Updated:** August 2026

---

## Overview

There are three ways to run PowerShell against another computer, and picking the wrong one is the usual reason a command that works locally fails remotely:

1. **Native support in the cmdlet** — the cmdlet has its own `-ComputerName` (or `-Computer`) parameter.
2. **Wrap it in `Invoke-Command`** — which always has `-ComputerName`.
3. **Open a remote session** — best when you want to run several commands.

The important thing to understand up front is that these use **different plumbing**. Methods 2 and 3 go over WinRM and need `Enable-PSRemoting` on the target. Most Method 1 cmdlets pre-date WinRM and use RPC/DCOM instead — which is why they sometimes work on a machine where remoting was never enabled, and sometimes fail on one where it was.

**PowerShell 7 caveat:** several of the classic `-ComputerName` parameters were **removed** in PowerShell 7 to push everyone toward `Invoke-Command`. If you learned Method 1 on 5.1, some of it no longer works. See the table in Method 1.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Rights on the target | Local Administrator, or membership in **Remote Management Users** |
| Remoting enabled | `Enable-PSRemoting` on the target for Methods 2 and 3 (see the WinRM section) |
| Network | Private or Domain firewall profile. Public blocks remoting by default |
| Ports | **5985** (HTTP) / **5986** (HTTPS) for WinRM. Method 1 cmdlets need RPC — **135** plus the dynamic range |
| Name resolution | The target must resolve. In a workgroup you'll also need TrustedHosts |

---

## Method 1 — Native cmdlet support

Some cmdlets accept a computer name directly. No session, no setup — easiest way to go when it's available.

```powershell
Get-EventLog -ComputerName CN-WS1          # Windows PowerShell 5.1 only
Invoke-GPUpdate -Computer CN-WS1
Get-Process -ComputerName CN-WS1           # Windows PowerShell 5.1 only
Get-Service -ComputerName CN-WS1           # Windows PowerShell 5.1 only
Restart-Computer -ComputerName CN-WS1
```

Note `Invoke-GPUpdate` uses `-Computer`, not `-ComputerName` — the parameter name isn't consistent across modules. When in doubt:

```powershell
Get-Help Get-Service -Parameter ComputerName
```

Or list every cmdlet in the current session that supports it:

```powershell
Get-Command -ParameterName ComputerName
```

### What changed in PowerShell 7

| Cmdlet | 5.1 | 7.x | Do this instead in 7.x |
|---|---|---|---|
| `Get-EventLog` | ✅ | ❌ **Cmdlet removed** | `Get-WinEvent -ComputerName CN-WS1 -LogName System` |
| `Get-Process` | ✅ | ❌ `-ComputerName` removed | `Invoke-Command -ComputerName CN-WS1 { Get-Process }` |
| `Get-Service` | ✅ | ❌ `-ComputerName` removed | `Invoke-Command -ComputerName CN-WS1 { Get-Service }` |
| `Restart-Computer` | ✅ | ✅ Still supported | Add `-WsmanAuthentication Kerberos` if needed |
| `Rename-Computer` | ✅ | ✅ Still supported | — |
| `Get-WinEvent` | ✅ | ✅ Still supported | — |
| `Invoke-GPUpdate` | ✅ | ✅ (RSAT module) | — |

The `-ComputerName` parameter was pulled from the `*-Service` cmdlets specifically to encourage consistent use of PowerShell remoting. `*-EventLog` went because it relied on unsupported APIs. `Restart-Computer`, `Stop-Computer`, and `Rename-Computer` kept `-ComputerName` but lost `-Protocol` — DCOM is gone and they're WSMan-only in 7.x.

**MSP note:** This is the single most common "it worked on my other machine" support call. A tech runs `Get-Service -ComputerName` from the ISE on 5.1, it works; the same line in a PS7 console errors on the parameter. Standardize on `Invoke-Command` for scripts you ship to multiple techs — it behaves identically on both versions.

---

## Method 2 — Invoke-Command

Put the cmdlet you want inside the `Invoke-Command` envelope. Works with anything, regardless of whether the cmdlet has its own `-ComputerName`.

```powershell
Invoke-Command -ComputerName CN-WS1 -ScriptBlock { Start-Service -Name eventlog }

Invoke-Command -ComputerName CN-WS1 -FilePath C:\scripts\script.ps1
```

`-FilePath` reads the script from *your* machine and runs it on the target — the file does not need to exist on the remote computer.

### Multiple computers

Separate names with commas. `Invoke-Command` fans out in parallel:

```powershell
Invoke-Command -ComputerName CN-WS1, CN-WS2, CN-WS3 -ScriptBlock { Get-Service -Name eventlog }
```

Or from a list:

```powershell
$computers = Get-Content C:\scripts\workstations.txt
Invoke-Command -ComputerName $computers -ScriptBlock { Get-Service -Name eventlog }
```

By default it runs against **32 machines at a time**; raise or lower that with `-ThrottleLimit`. Results come back with a `PSComputerName` property so you can tell which machine said what:

```powershell
Invoke-Command -ComputerName $computers -ScriptBlock { Get-Service -Name eventlog } |
    Select-Object PSComputerName, Name, Status
```

### Passing local variables into the script block

The script block runs on the remote machine, so your local variables don't exist inside it. Prefix them with `$using:`:

```powershell
$serviceName = "eventlog"
Invoke-Command -ComputerName CN-WS1 -ScriptBlock { Get-Service -Name $using:serviceName }
```

Forgetting `$using:` is the classic silent failure — the variable is simply empty on the far side, so the command runs with no filter or errors on a null parameter.

### Alternate credentials

```powershell
$cred = Get-Credential
Invoke-Command -ComputerName CN-WS1 -Credential $cred -ScriptBlock { Get-Service }
```

---

## Method 3 — Remote session

Use a session when you want to run **multiple** commands without re-establishing the connection each time.

### Interactive (`Enter-PSSession`)

Your prompt changes to show the remote machine. Everything you type runs there until you exit.

```powershell
Enter-PSSession SR-DC1

Get-Service | Sort-Object Status
Get-NetIPConfiguration
<other cmdlets as needed>

Exit-PSSession
```

The prompt will read `[SR-DC1]: PS C:\>` — check for that before you start typing destructive commands. `Enter-PSSession` connects to **one** computer only.

### Persistent (`New-PSSession`)

A saved session object you can reuse across multiple `Invoke-Command` calls, keeping state (variables, imported modules) between them:

```powershell
$s = New-PSSession -ComputerName SR-DC1

Invoke-Command -Session $s -ScriptBlock { $svc = Get-Service | Where-Object Status -eq 'Running' }
Invoke-Command -Session $s -ScriptBlock { $svc.Count }   # $svc still exists

Remove-PSSession $s
```

Always `Remove-PSSession` when finished — orphaned sessions consume a connection slot on the target and there's a per-user limit.

`New-PSSession` also accepts multiple computers, giving you a session array to fan out against.

---

## Choosing a method

| Situation | Use |
|---|---|
| One quick command, cmdlet has `-ComputerName`, you're on 5.1 | Method 1 |
| One command, any cmdlet, any PowerShell version | Method 2 (`Invoke-Command`) |
| Same command across many machines | Method 2 with a computer array |
| Running a local `.ps1` against a remote machine | Method 2 with `-FilePath` |
| Poking around interactively, troubleshooting | Method 3 (`Enter-PSSession`) |
| Several commands that need to share state | Method 3 (`New-PSSession`) |
| Writing a script other techs will run on mixed 5.1/7.x | Method 2 — most portable |

---

## PowerShell, WinRM, and the firewall

**WinRM** = Windows Remote Management, Microsoft's implementation of the **WS-Management** web standard. It's the transport behind Methods 2 and 3.

### Enabling it

On the **remote** PC, in an **elevated** PowerShell session:

```powershell
Enable-PSRemoting
```

That one command:

- Starts the **WinRM** service
- Sets the service to **Automatic** startup
- Creates a **WinRM listener** for HTTP on port 5985
- Enables the required **firewall exceptions**
- Registers the PowerShell session configuration (endpoint)

**By default it only works on Private and Domain networks, not Public.** On a Public profile the command fails with a network-profile error. Either move the adapter to Private, or override:

```powershell
Enable-PSRemoting -SkipNetworkProfileCheck -Force
```

`-SkipNetworkProfileCheck` still creates a firewall rule scoped to the local subnet only — it does not expose the machine to the internet. Don't widen that rule casually.

**MSP note:** On a domain, don't walk to every desktop. Enable remoting fleet-wide with Group Policy: **Computer Configuration > Policies > Administrative Templates > Windows Components > Windows Remote Management (WinRM) > WinRM Service > Allow remote server management through WinRM**, plus a policy to set the **WinRM service to Automatic** and the firewall rule for **Windows Remote Management (HTTP-In)**. On Windows Server, remoting is already on by default.

### PowerShell 7 registers its own endpoint

This trips people up constantly. `Enable-PSRemoting` configures an endpoint **for the version of PowerShell you ran it in**. Running it inside PowerShell 7.4 creates endpoints named `PowerShell.7.4` and `PowerShell.7.4.7` — it does **not** change the default endpoint, which stays Windows PowerShell 5.1.

So connecting normally lands you in 5.1 even if PS7 is installed on both ends. To get a PS7 session, name the configuration:

```powershell
Enter-PSSession -ComputerName SR-DC1 -ConfigurationName PowerShell.7.4

New-PSSession -ComputerName SR-DC1 -ConfigurationName PowerShell.7.4
```

List what a target actually offers:

```powershell
Invoke-Command -ComputerName SR-DC1 -ScriptBlock { Get-PSSessionConfiguration | Select-Object Name }
```

If you don't know the exact version suffix, that's how you find it. Check `$PSVersionTable` *inside* the session to confirm which engine you landed in.

### Workgroup / non-domain targets

Without Kerberos there's no mutual authentication, so you must explicitly trust the target on the **client**:

```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "CN-WS1" -Concatenate
Get-Item WSMan:\localhost\Client\TrustedHosts
```

Then connect with `-Credential`. `-Concatenate` appends rather than overwriting the existing list — omit it and you'll silently wipe entries other tooling depends on. Avoid `-Value "*"`.

### The double-hop problem

Credentials do not forward past the first remote machine. Inside a remote session, reaching a *third* resource (a file share, a SQL box, another DC) fails with access denied even though the same command works locally. Fixes, in order of preference: pass an explicit `-Credential` on the inner command, use resource-based Kerberos constrained delegation, or — last resort, since it sends reusable credentials to the target — CredSSP.

---

## Verification / Testing Checklist

- [ ] `Test-WSMan -ComputerName CN-WS1` returns identity info rather than an error
- [ ] `Get-Service WinRM -ComputerName CN-WS1` (5.1) or via `Invoke-Command` shows **Running**, StartType **Automatic**
- [ ] `Test-NetConnection CN-WS1 -Port 5985` succeeds
- [ ] `Invoke-Command -ComputerName CN-WS1 -ScriptBlock { $env:COMPUTERNAME }` returns the *remote* name
- [ ] `Enter-PSSession CN-WS1` changes the prompt to `[CN-WS1]:`
- [ ] If PS7 is required: `Invoke-Command ... { $PSVersionTable.PSVersion }` reports 7.x, not 5.1
- [ ] `Get-PSSession` is empty after you finish (no orphaned sessions)

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `WinRM cannot complete the operation ... verify that the specified computer name is valid` | Name doesn't resolve, host offline, or firewall blocking 5985 | `Test-NetConnection CN-WS1 -Port 5985`; check DNS and the firewall profile |
| `Access is denied` on connect | Account isn't a local admin / Remote Management User on the target | Add to **Remote Management Users**, or pass `-Credential` |
| `The WinRM client cannot process the request ... default authentication` | Workgroup target not in TrustedHosts | Add it with `Set-Item WSMan:\localhost\Client\TrustedHosts` and supply `-Credential` |
| `Enable-PSRemoting` fails on network profile | Adapter is on a Public network | Set the profile to Private, or use `-SkipNetworkProfileCheck` |
| `A parameter cannot be found that matches parameter name 'ComputerName'` | Running a 5.1-era example in PowerShell 7 | Use `Invoke-Command` (see the Method 1 table) |
| `The term 'Get-EventLog' is not recognized` | Cmdlet removed in PowerShell 7 | Use `Get-WinEvent` |
| Connected fine, but `$PSVersionTable` shows 5.1 | Default endpoint is Windows PowerShell | Reconnect with `-ConfigurationName PowerShell.7.4` |
| Script block behaves as if a variable is empty | Local variable not passed into the remote scope | Prefix with `$using:` |
| Access denied reaching a share *from inside* a session | Double-hop — credentials don't forward | Pass explicit `-Credential` inside, or configure delegation |
| `Maximum number of concurrent shells` | Orphaned sessions on the target | `Get-PSSession -ComputerName X \| Remove-PSSession`; always clean up |
| Command works on one host, times out on 30 | Fan-out throttle or slow targets | Tune `-ThrottleLimit`, raise `-OperationTimeout` |

---

## Sources

- Microsoft Learn: [Running Remote Commands](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/running-remote-commands)
- Microsoft Learn: [Using WS-Management (WSMan) Remoting in PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/wsman-remoting-in-powershell)
- Microsoft Learn: [Differences between Windows PowerShell 5.1 and PowerShell 7.x](https://learn.microsoft.com/en-us/powershell/scripting/whats-new/differences-from-windows-powershell)
- Microsoft Learn: [Enable-PSRemoting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting)
- Microsoft Learn: [Invoke-Command](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/invoke-command)
- Microsoft Learn: [Making the second hop in PowerShell Remoting](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/ps-remoting-second-hop)
