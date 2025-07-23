# Role Management Test

This dynamic test screen allows you to interactively test the role management operations from the Flutter Policy Engine.

## Features

### 1. Current Roles Display

- Shows all currently available roles in the system
- Displays permissions for each role
- Click on any role to select it for testing or editing

### 2. Role Management Operations

Test the three main role management functions:

#### Add Role

- Enter a new role name and permissions
- Permissions should be comma-separated (e.g., "LoginPage, Dashboard, Settings")
- Click "Add Role" to create the new role

#### Update Role

- Select an existing role or enter a role name
- Modify the permissions as needed
- Click "Update Role" to apply changes

#### Remove Role

- Enter the name of the role to remove
- Click "Remove Role" to delete it from the system

### 3. Policy Testing

- Select any role from the available roles
- See real-time policy evaluation for different content types:
  - Login Page
  - Dashboard
  - User Management
  - Settings
- Green cards indicate access granted
- Red cards indicate access denied

## Usage Examples

### Adding a New Role

1. Enter role name: "moderator"
2. Enter permissions: "LoginPage, Dashboard, UserManagement"
3. Click "Add Role"
4. The new role appears in the Current Roles list

### Testing Access Control

1. Select "admin" role
2. Observe that all content types show green (access granted)
3. Switch to "guest" role
4. Observe that only Login Page shows green, others show red (access denied)

### Updating Permissions

1. Click on "user" role in the Current Roles list
2. The form will be populated with current permissions
3. Add "Settings" to the permissions field
4. Click "Update Role"
5. Test the updated permissions in the Policy Testing section

## Technical Details

This test screen demonstrates:

- `PolicyManager.addRole()` - Adding new roles
- `PolicyManager.removeRole()` - Removing existing roles
- `PolicyManager.updateRole()` - Updating role permissions
- `PolicyWidget` - Real-time policy evaluation
- Error handling and user feedback
- Dynamic UI updates based on policy changes

## Error Handling

The test includes comprehensive error handling:

- Validation for empty role names
- Try-catch blocks for all operations
- User-friendly status messages
- Automatic status message clearing after 3 seconds

## Integration

This test screen is accessible from the main app home screen and provides a comprehensive way to validate the role management functionality of the Flutter Policy Engine.
