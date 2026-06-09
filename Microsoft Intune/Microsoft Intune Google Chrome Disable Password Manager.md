# Settings Catalog - Chrome Password Manager - User

## Summary

This policy disables Google Chrome's built-in password manager for end users. When applied, Chrome will no longer prompt users to save passwords, and access to previously saved passwords within Chrome is blocked. This is commonly deployed in environments where a centrally managed password manager (such as 1Password, Bitwarden, or Microsoft's native tools) is the approved solution, or where security policy prohibits local credential storage in browsers.

---

## Policy Details

| Field | Value |
|---|---|
| **Policy Name** | Settings Catalog - Chrome Password Manager - User |
| **Platform** | Windows 10 and later |
| **Profile Type** | Settings Catalog |
| **Targeted Setting** | Enable saving passwords to the password manager |
| **Value** | Disabled |

---

## Configuration Steps

1. Sign in to the [Microsoft Intune admin center](https://intune.microsoft.com)
2. Navigate to **Devices** > **Configuration** > **+ Create** > **New Policy**
3. Set the following:
   - **Platform:** Windows 10 and later
   - **Profile type:** Settings Catalog
4. Click **Next** and give the policy the name: `Settings Catalog - Chrome Password Manager - User`
5. On the **Configuration settings** tab, click **+ Add settings**
6. In the settings picker, search for `Password Manager`
7. Under the **Google Chrome** category, select **Enable saving passwords to the password manager**
8. Close the settings picker and set the toggle to **Disabled**
9. Click **Next**, configure any applicable **Scope tags**, then proceed to **Assignments**
10. Assign the policy to the appropriate user or device group
11. Click **Next** and then **Create** to save and deploy the policy

---

## Notes

- This policy maps to the Chrome GPO setting `PasswordManagerEnabled`. Setting it to disabled hides the "Save password?" prompt and removes access to the Chrome password vault.
- This policy does **not** delete previously saved passwords — it only blocks access to them while the policy is in effect. Passwords are recoverable if the policy is removed.
- If users are signed into a Google account with Chrome Sync enabled, passwords synced to their Google account are not affected by this policy. Consider also restricting Chrome sign-in if that is a concern in your environment.
- Test on a pilot group before broad deployment. Users who rely on Chrome's password manager will lose access to saved credentials while this policy is active.
