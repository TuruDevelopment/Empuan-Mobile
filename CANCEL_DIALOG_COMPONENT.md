# Cancel Dialog Component Documentation

## Overview

Reusable modern cancel dialog component dengan desain konsisten menggunakan Burgundy/Maroon theme.

## Location

`lib/components/cancel_dialog.dart`

## Design Specifications

### Visual Elements

1. **Icon Container**

   - Size: 48px icon dalam container circle
   - Gradient background: error color dengan opacity 0.2 → 0.1
   - Icon: `Icons.warning_amber_rounded`
   - Color: `AppColors.error`

2. **Content**

   - Title: Satoshi Bold 20px
   - Message: Satoshi Regular 14px
   - Text alignment: Center
   - Spacing: 24px after icon, 12px between title and message

3. **Buttons**

   - Height: 48px
   - Border radius: 12px
   - Spacing: 12px between buttons
   - Layout: Row with equal width (Expanded)

4. **Cancel Button** (Left)

   - Background: Surface white
   - Border: Accent color opacity 0.5, width 1.5px
   - Text: Satoshi Bold 15px, textPrimary color

5. **Confirm Button** (Right)
   - Gradient: error → error opacity 0.8
   - Text: Satoshi Bold 15px, white color
   - No shadow (handled by container)

## Usage

### Basic Usage

```dart
import 'package:Empuan/components/cancel_dialog.dart';

// Simple usage with default values
showCancelDialog(context: context);
```

### Custom Text

```dart
showCancelDialog(
  context: context,
  title: 'Leave Page?',
  message: 'Changes you made may not be saved.',
  cancelButtonText: 'Stay',
  confirmButtonText: 'Leave',
);
```

### Custom Actions

```dart
showCancelDialog(
  context: context,
  onConfirm: () {
    // Custom action instead of navigating to StartPage
    Navigator.of(context).pop();
    // Do something else
  },
  onCancel: () {
    // Optional: additional action when cancel is pressed
    print('User cancelled');
  },
);
```

## Parameters

| Parameter           | Type            | Default                                                              | Description                                               |
| ------------------- | --------------- | -------------------------------------------------------------------- | --------------------------------------------------------- |
| `context`           | `BuildContext`  | required                                                             | Build context for showing dialog                          |
| `title`             | `String`        | `'Cancel Registration?'`                                             | Dialog title text                                         |
| `message`           | `String`        | `'Are you sure you want to cancel? All your progress will be lost.'` | Dialog message text                                       |
| `cancelButtonText`  | `String`        | `'Go Back'`                                                          | Text for cancel button                                    |
| `confirmButtonText` | `String`        | `'Yes, Cancel'`                                                      | Text for confirm button                                   |
| `onConfirm`         | `VoidCallback?` | `null`                                                               | Custom action on confirm (default: navigate to StartPage) |
| `onCancel`          | `VoidCallback?` | `null`                                                               | Optional action on cancel (default: just close dialog)    |

## Default Behavior

### Cancel Button

- Closes the dialog
- Executes `onCancel` callback if provided
- No navigation

### Confirm Button

- If `onConfirm` is provided: executes the callback
- If `onConfirm` is null: navigates to `StartPage` using `pushReplacement`

## Implementation Examples

### Example 1: Registration Flow (Default)

Used in: `accountCred.dart`, `genderVerif.dart`, `tempSignUpPage.dart`

```dart
IconButton(
  onPressed: () {
    showCancelDialog(context: context);
  },
  icon: Icon(Icons.close_rounded),
)
```

**Behavior**: Shows warning about losing progress, navigates to StartPage on confirm.

### Example 2: Form with Custom Action

```dart
showCancelDialog(
  context: context,
  title: 'Discard Changes?',
  message: 'You have unsaved changes. Are you sure you want to discard them?',
  cancelButtonText: 'Keep Editing',
  confirmButtonText: 'Discard',
  onConfirm: () {
    // Clear form
    formKey.currentState?.reset();
    Navigator.of(context).pop();
  },
);
```

### Example 3: Delete Confirmation

```dart
showCancelDialog(
  context: context,
  title: 'Delete Item?',
  message: 'This action cannot be undone.',
  cancelButtonText: 'Cancel',
  confirmButtonText: 'Delete',
  onConfirm: () async {
    Navigator.of(context).pop(); // Close dialog
    await deleteItem();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item deleted')),
    );
  },
);
```

## Design Consistency

### Color Scheme

- Error gradient: `AppColors.error` → `AppColors.error.withOpacity(0.8)`
- Border: `AppColors.accent.withOpacity(0.5)`
- Text primary: `AppColors.textPrimary`
- Text secondary: `AppColors.textSecondary`
- Surface: `AppColors.surface`

### Typography

- Title: Satoshi Bold 20px
- Message: Satoshi Regular 14px
- Buttons: Satoshi Bold 15px

### Spacing

- Dialog padding: 24px all sides
- Icon to title: 24px
- Title to message: 12px
- Button height: 48px
- Button spacing: 12px

## Files Updated

1. **Created**

   - `lib/components/cancel_dialog.dart` - Main component

2. **Modified**

   - `lib/accountCred.dart` - Replaced `_showCloseDialog` with `showCancelDialog`
   - `lib/genderVerif.dart` - Replaced `_showCloseDialog` with `showCancelDialog`
   - `lib/tempSignUpPage.dart` - Replaced `_showCloseDialog` with `showCancelDialog`

3. **Removed Functions**
   - Deleted duplicate `_showCloseDialog` functions from all 3 files above
   - Reduced code duplication by ~140 lines per file

## Benefits

1. **Consistency**: Same design across all pages
2. **Reusability**: One component, multiple uses
3. **Maintainability**: Single place to update design
4. **Flexibility**: Customizable text and actions
5. **Clean Code**: Reduced duplication

## Future Enhancements

Potential improvements:

- Add different icon options (warning, info, question)
- Add color theme variants (error, warning, info)
- Add custom icon support
- Add animation options
- Add sound/haptic feedback options

## Testing

To test the component:

```dart
// Test 1: Default behavior
showCancelDialog(context: context);
// Expected: Shows dialog, confirm navigates to StartPage

// Test 2: Custom text
showCancelDialog(
  context: context,
  title: 'Test Title',
  message: 'Test Message',
);
// Expected: Shows custom text

// Test 3: Custom action
bool confirmed = false;
showCancelDialog(
  context: context,
  onConfirm: () {
    confirmed = true;
    Navigator.of(context).pop();
  },
);
// Expected: Sets confirmed to true, doesn't navigate

// Test 4: Cancel button
showCancelDialog(
  context: context,
  onCancel: () {
    print('Cancelled');
  },
);
// Expected: Prints 'Cancelled' when cancel is pressed
```

## Notes

- Dialog is **not** barrierDismissible (user must choose an option)
- Confirm button uses gradient container with ElevatedButton for proper transparency
- Cancel button uses border with TextButton for outline effect
- Both buttons have rounded corners (12px radius)
- Component handles navigation by default but can be overridden

---

**Created**: October 13, 2025
**Component Version**: 1.0.0
**Design System**: Burgundy/Maroon Theme
