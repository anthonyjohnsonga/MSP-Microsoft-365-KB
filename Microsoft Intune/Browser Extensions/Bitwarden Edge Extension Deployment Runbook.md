# Intune Runbook: Deploy the Bitwarden Extension to Microsoft Edge

**Applies to:** Microsoft Intune, Microsoft Edge, Bitwarden Password Manager  
**Scope:** Silently install and force-show the official Bitwarden extension for targeted users through an Intune Settings Catalog policy.  
**Last Updated:** September 2026

---

## Purpose

This runbook explains how to create a user-scoped Microsoft Intune Settings Catalog policy that silently installs the official Bitwarden Password Manager extension in Microsoft Edge.

## Policy Summary

| Item | Configuration |
| --- | --- |
| Platform | Windows 10 and later |
| Profile type | Settings catalog |
| Policy name | Edge - Extensions - Bitwarden |
| Policy scope | User |
| Edge settings | Control which extensions are installed silently; Configure extension management settings |
| Bitwarden Edge extension ID | `jbkfoedolllekgbhcbcoahefnbanhhlh` |
| Toolbar behavior | Force shown |
| Recommended assignment | Pilot user group, followed by the applicable production user group |

## Prerequisites

- Access to the Microsoft Intune admin center with permission to create and assign device configuration policies.
- Microsoft Edge installed on the targeted Windows devices.
- Targeted users and devices enrolled in Microsoft Intune.
- A pilot user group for initial testing.

## Create the Policy

1. Sign in to the [Microsoft Intune admin center](https://intune.microsoft.com/).
2. Navigate to **Devices > Windows > Configuration**.
3. Select **Create > New policy**.
4. Configure the new policy:

   - **Platform:** Windows 10 and later
   - **Profile type:** Settings catalog

5. Select **Create**.
6. On the **Basics** page, enter:

   - **Name:** `Edge - Extensions - Bitwarden`
   - **Description:** `Silently installs the Bitwarden Password Manager extension in Microsoft Edge for assigned users.`

7. Select **Next**.

## Configure the Edge Extension Setting

1. On the **Configuration settings** page, select **Add settings**.
2. Search for:

   ```text
   Control which extensions are installed silently
   ```

3. Select the user-scoped setting under:

   **Microsoft Edge > Extensions > Control which extensions are installed silently (User)**

   The label may vary slightly as the Intune interface is updated. Select the version identified as a **User** setting rather than the device setting.

4. Close the Settings picker.
5. Set **Control which extensions are installed silently** to **Enabled**.
6. Add the following value to the extension list:

   ```text
   jbkfoedolllekgbhcbcoahefnbanhhlh
   ```

7. Select **Next**.

The extension ID is sufficient because Bitwarden is published in the Microsoft Edge Add-ons store. A separate update URL is not required.

## Force the Extension to Appear on the Toolbar

The silent-install setting installs Bitwarden and prevents users from removing it. Add the following setting to the same policy to force the Bitwarden icon to remain visible on the Edge toolbar.

1. While still on the **Configuration settings** page, select **Add settings**.
2. Search for:

   ```text
   Configure extension management settings
   ```

3. Select the user-scoped setting under:

   **Microsoft Edge > Extensions > Configure extension management settings (User)**

   The label may vary slightly as the Intune interface is updated. Select the version identified as a **User** setting so that it matches the silent-install setting and user-group assignment.

4. Close the Settings picker.
5. Set **Configure extension management settings** to **Enabled**.
6. Enter the following JSON as a single line:

   ```json
   {"jbkfoedolllekgbhcbcoahefnbanhhlh":{"installation_mode":"force_installed","update_url":"https://edge.microsoft.com/extensionwebstorebase/v1/crx","toolbar_state":"force_shown"}}
   ```

7. Continue to the next page of the policy wizard.

This JSON performs three related actions:

- `installation_mode` confirms that Bitwarden is force-installed and cannot be disabled or removed by the user.
- `update_url` directs the initial installation to the Microsoft Edge Add-ons store.
- `toolbar_state` forces the Bitwarden icon to remain visible on the Edge toolbar.

Keep the Bitwarden ID in **Control which extensions are installed silently**. Although the installation directive appears in both settings, including the complete installation configuration in the JSON prevents the higher-precedence `ExtensionSettings` policy from weakening the force-install requirement.

> Enter the JSON as plain text. Do not include Markdown link formatting, escaped underscores such as `installation\_mode`, or additional characters before or after the JSON.

## Scope Tags

1. Add the appropriate scope tag if the organization uses role-based administration and scope tags.
2. Otherwise, retain the default scope tag.
3. Select **Next**.

## Assign the Policy

1. Under **Included groups**, select **Add groups**.
2. Select the pilot **user group** that should receive Bitwarden.
3. Configure exclusions if required.
4. Select **Next**.
5. Review the configuration and select **Create**.

After successful pilot testing, add the applicable production user group or groups to the policy assignment.

> Because this policy uses the user-scoped Edge setting, assign it to user groups. A device-scoped policy should normally be assigned to device groups.

## Expected Result

After the user receives the policy and starts Microsoft Edge:

- Bitwarden installs without user interaction or local administrator rights.
- The user cannot disable or uninstall the extension.
- The Bitwarden icon remains visible on the Microsoft Edge toolbar and cannot be hidden by the user.
- Edge updates the extension through the Microsoft Edge Add-ons store.
- On shared computers, only targeted users receive the user-scoped policy.
- The policy follows the targeted user to other applicable Intune-managed Windows devices.

## Validate on a Targeted Device

### Verify the Edge Policy

1. Sign in to Windows as a targeted pilot user.
2. Open Microsoft Edge.
3. Navigate to:

   ```text
   edge://policy
   ```

4. Select **Reload policies**.
5. Locate both of the following policies:

   - `ExtensionInstallForcelist`
   - `ExtensionSettings`

6. Confirm that `ExtensionInstallForcelist` contains `jbkfoedolllekgbhcbcoahefnbanhhlh`.
7. Confirm that `ExtensionSettings` contains the Bitwarden configuration, including:

   - `installation_mode` set to `force_installed`
   - `toolbar_state` set to `force_shown`
   - The Microsoft Edge Add-ons `update_url`

8. Confirm that:

   - Both policies show **Current user** or **User** as their scope.
   - Both policies show **OK** and do not report an error.

### Verify the Extension

1. In Microsoft Edge, navigate to:

   ```text
   edge://extensions
   ```

2. Confirm that **Bitwarden - Free Password Manager** is installed.
3. Confirm that Edge identifies the extension as managed by the organization.
4. Confirm that the Bitwarden icon appears on the Edge toolbar and cannot be hidden by the user.

### Verify in Intune

1. Open the policy in the Intune admin center.
2. Review **Device and user check-in status**.
3. Confirm that the pilot user reports a successful status.

## Troubleshooting

If Bitwarden does not install:

1. Confirm that the user is a member of the included user group and is not a member of an excluded group.
2. Confirm that the Windows device is enrolled and checking in with Intune.
3. From **Access work or school** on the device, select the connected work account and initiate a synchronization.
4. Restart Microsoft Edge and reload `edge://policy`.
5. Check for a device-scoped Edge policy configuring the same setting. A conflicting device-level Edge policy can take precedence over a user-level policy.
6. Confirm that outbound access to the Microsoft Edge Add-ons service is not blocked by a firewall, proxy, or web-filtering policy.
7. If `ExtensionSettings` reports an error, confirm that the JSON uses straight quotation marks, contains no escaped underscores or Markdown formatting, and exactly matches the documented single-line value.

## Removal or Rollback

To stop forcing Bitwarden for the targeted users, remove their group from the policy assignment or remove the Bitwarden extension ID from the policy.

Microsoft Edge may automatically uninstall an extension when it is removed from the force-install list. Test the rollback with a pilot user before making the change broadly.

## Sources

- [Microsoft Edge ExtensionInstallForcelist policy](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/extensioninstallforcelist)
- [Microsoft Edge ExtensionSettings policy guide](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-manage-extensions-ref-guide)
- [Deploy Bitwarden browser extensions with Intune](https://bitwarden.com/help/deploy-browser-extensions-with-intune/)
