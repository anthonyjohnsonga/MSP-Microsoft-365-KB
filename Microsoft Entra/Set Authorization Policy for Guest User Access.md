# Set Authorization Policy for Guest User Access

## Configuration Options Summary

Guest user access authorization policy in Microsoft Entra ID can be configured using two methods:

| Method | Requirements | Best For |
|---|---|---|
| **Microsoft Entra Admin Center (GUI)** | Privileged Role Administrator (minimum) | One-time or ad-hoc changes without scripting |
| **Microsoft Graph API** | Appropriate API permissions + authenticated session | Automated, repeatable, or scripted deployments |

Both methods apply the same tenant-wide policy and changes can take up to 15 minutes to take effect.

## Overview

The authorization policy for guest user access in Microsoft Entra ID (formerly Azure AD) is a tenant-wide configuration that controls the permission levels assigned to external guest users. Administrators use the **authorizationPolicy** resource in the Microsoft Graph API to define what guest users can see and do within the directory. By default, guest users have limited permissions compared to member users, though organizations can adjust this based on security and collaboration requirements.

## Guest User Access Levels

Microsoft Entra ID supports three configurable guest access permission levels, each identified by a `guestUserRoleId` GUID:

| Access Level | Description | GUID |
|---|---|---|
| **User (Member)** | Same access as member users — can view all directory info and invite other guests | `a0b1b346-4d3e-4e8b-98f8-753987be4970` |
| **Guest User** (default) | Restricted to viewing limited properties and group memberships of other users | `10dae51f-b6af-4016-8d66-8c2a99b929b3` |
| **Restricted Guest User** | Most restrictive — can only view their own profile, cannot search for other users or see group memberships | `2af84b1e-32c8-42b7-82bc-daa82404023b` |

## Why Administrators Configure This Policy

Administrators implement guest access restrictions to balance security and collaboration. Organizations with strict security requirements may adopt the restricted guest model to prevent external users from discovering sensitive directory structure or conducting enumeration attacks. Conversely, organizations that frequently collaborate with external partners may maintain higher guest permissions to enable seamless participation. The authorization policy is a global tenant setting that applies across all applications and services within the directory.

## Configuration Method

The authorization policy is configured through the Microsoft Graph API via a `PATCH /policies/authorizationPolicy/authorizationPolicy` request, with the `guestUserRoleId` parameter set to the desired access level GUID. Organizations can also use the Microsoft Entra admin center UI to configure external collaboration settings without needing direct API calls.

## Configuring via the Microsoft Entra Admin Center (GUI)

This policy can also be configured directly through the Microsoft Entra admin center without using the Graph API.

### Required Role

The minimum required role depends on what you are configuring:

| Setting | Minimum Required Role |
|---|---|
| Guest user access level | Privileged Role Administrator |
| Guest invite settings | Guest Inviter |
| External user leave settings | External Identity Provider Administrator |
| Collaboration restrictions (allow/block domains) | Global Administrator |

### Steps

1. Sign in to the **Microsoft Entra admin center**
2. Navigate to **Entra ID > External Identities > External collaboration settings**
3. Under **Guest user access**, select the desired access level
4. Click **Save**

> **Note:** Changes can take up to 15 minutes to take effect for guest users.
