# Azure MS-Graph App Setup for Autopilot Registration

## Required APIs/Permissions
Create an app in **Azure MS-Graph** with the following API permissions:

- `DeviceManagementServiceConfig.ReadWrite.All`
- `Directory.ReadWrite.All`
- `GroupMember.ReadWrite.All`

## Authentication
For the app's authentication, use the **"Secrets"** type for the key.

## Script Configuration
Update the **`Autopilot.ps1`** script with your organization's specific details and the app credentials:

- `Tenant ID`: Your Azure Tenant ID.
- `App ID`: The Application (Client) ID of the created app.
- `App secret`: The secret key generated for the app.

## Execution Instructions
1. Place both files (**`Autopilot.ps1`** and **`Autopilot.cmd`**) in the same folder.
2. Run **`Autopilot.cmd`** on each device you want to register in Autopilot.

### Process Overview
- The script will handle the registration of the device.
- Once the process completes, the device will shut down automatically.
- After restarting, the device will be registered in **Autopilot** and ready to proceed with the OOBE (Out-Of-Box Experience).

Ensure the correct permissions and details are provided to avoid errors during the registration process.
