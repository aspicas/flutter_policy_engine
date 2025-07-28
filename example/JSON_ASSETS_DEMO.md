# JSON Assets Demo

This demo showcases the `initializeFromJsonAssets` method of the Flutter Policy Engine, demonstrating how to load policy configurations from JSON asset files bundled with your Flutter application.

## Overview

The JSON Assets Demo provides an interactive interface to:

- Initialize the policy manager from a JSON asset file
- Test role-based permissions
- Test content access control
- View detailed role information

## Features

### 1. Asset-based Policy Loading

- Loads policies from `assets/policies/user_roles.json`
- Demonstrates the `initializeFromJsonAssets` method
- Shows real-time initialization status

### 2. Interactive Testing

- **Role Selection**: Choose from predefined roles (admin, manager, editor, viewer, guest)
- **Permission Testing**: Test if a role has specific permissions
- **Content Access Testing**: Verify content access using the `hasAccess` method
- **Role Information**: View detailed role configuration

### 3. Real-time Feedback

- Visual status indicators
- Detailed error messages
- Test results with clear success/failure indicators

## JSON Asset Format

The demo uses a JSON file with the following structure:

```json
{
  "admin": {
    "allowedContent": [
      "read",
      "write",
      "delete",
      "manage_users",
      "system_config",
      "all",
      "admin_panel",
      "user_management",
      "system_settings"
    ]
  },
  "manager": {
    "allowedContent": [
      "read",
      "write",
      "manage_team",
      "team_content",
      "reports",
      "analytics",
      "public"
    ]
  }
}
```

### Required Fields

- `allowedContent`: Array of strings representing permissions and content access

## Usage

1. **Launch the Demo**: Select "JSON Assets Demo" from the main menu
2. **Initialize**: The policy manager automatically initializes from the JSON asset
3. **Test Permissions**: Select a role and permission to test
4. **Test Content Access**: Use the `hasAccess` method to verify content access
5. **View Role Details**: Get comprehensive information about any role

## Implementation Details

### Asset Configuration

The JSON file is declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/policies/
```

### Policy Manager Initialization

```dart
final policyManager = PolicyManager();
await policyManager.initializeFromJsonAssets('assets/policies/user_roles.json');
```

### Permission Testing

```dart
final role = policyManager.roles[roleName];
final hasPermission = role?.allowedContent.contains(permission) ?? false;
```

### Content Access Testing

```dart
final hasAccess = policyManager.hasAccess(roleName, content);
```

## Available Roles

| Role    | Permissions                                      | Content Access                                      |
| ------- | ------------------------------------------------ | --------------------------------------------------- |
| admin   | read, write, delete, manage_users, system_config | all, admin_panel, user_management, system_settings  |
| manager | read, write, manage_team                         | team_content, reports, analytics, public            |
| editor  | read, write, publish                             | content_creation, drafts, published_content, public |
| viewer  | read                                             | public, published_content, reports                  |
| guest   | read                                             | public                                              |

## Error Handling

The demo includes comprehensive error handling:

- Asset loading failures
- JSON parsing errors
- Policy initialization errors
- Role not found scenarios
- Permission/content access validation

## Benefits

1. **External Configuration**: Policies can be updated without code changes
2. **Asset Bundling**: JSON files are bundled with the app for offline access
3. **Flexible Structure**: Easy to modify role permissions and content access
4. **Runtime Testing**: Interactive testing of policy configurations
5. **Clear Feedback**: Visual indicators and detailed error messages

This demo demonstrates how to effectively use the `initializeFromJsonAssets` method for flexible, asset-based policy management in Flutter applications.
