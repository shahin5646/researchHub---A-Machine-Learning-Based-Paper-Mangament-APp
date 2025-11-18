# Onboarding Screens

This folder contains the first-time user onboarding experience for Research Hub.

## Files

### role_selection_screen.dart
**Purpose**: First screen shown to new users to select their role

**Features**:
- 3 animated role cards (Student, Researcher, Faculty Member)
- Role-specific colors and gradients
- Icon-based visual representation
- Interactive selection with animations
- Smooth transitions

**Flow**:
1. User registers/logs in
2. If `hasCompletedOnboarding` is false → shown this screen
3. User taps a role card to select
4. Continue button activates
5. Navigates to RoleConfirmationScreen

### role_confirmation_screen.dart
**Purpose**: Confirmation screen where users review and confirm their role selection

**Features**:
- Full-screen gradient background (role-specific)
- Large role icon
- Feature list for selected role
- Confirm/Go Back actions
- Success animation on confirmation
- Updates Firestore with role

**Flow**:
1. Receives selected role from RoleSelectionScreen
2. Displays role-specific features
3. User confirms → Updates Firestore
4. Shows success dialog
5. Navigates to main app

## Role Options

### Student
- **Color**: Indigo (#4F46E5)
- **Icon**: School
- **Features**: Browse, download, bookmark, follow, participate

### Researcher
- **Color**: Cyan (#0891B2)
- **Icon**: Science
- **Features**: All student features + upload papers, public profile, collaborate

### Faculty Member
- **Color**: Red (#DC2626)
- **Icon**: Account Balance
- **Features**: All researcher features + mentoring, full profile management

## Integration

### Navigation Check (main.dart)
```dart
if (auth.isLoggedIn && !auth.currentUser!.hasCompletedOnboarding) {
  return RoleSelectionScreen();
}
```

### Database Update
When user confirms:
```dart
await authProvider.updateProfile({
  'role': selectedRole.name,
  'hasCompletedOnboarding': true,
});
```

## Design Patterns

### Animations
- FadeTransition for overall screen
- SlideTransition for content
- TweenAnimationBuilder for card entrance
- AnimatedContainer for selection state
- ScaleTransition for confirmation screen

### State Management
- Local state using StatefulWidget
- AnimationController for custom animations
- Consumer for accessing AuthProvider

### UI Patterns
- Gradient backgrounds
- Glass-morphism effects
- Role-specific color theming
- Micro-interactions
- Smooth transitions

## Testing

To test onboarding:
1. Create new Firebase user
2. Ensure `hasCompletedOnboarding` is false
3. Login
4. Should see RoleSelectionScreen
5. Select role → Confirm
6. Should navigate to main app

## Future Enhancements

- [ ] Add skip option (with limitations)
- [ ] Multi-language support
- [ ] Video introduction for each role
- [ ] Collect additional profile info
- [ ] Institution selection
- [ ] Research interests picker
- [ ] Profile photo upload during onboarding

## Related Files

- `lib/models/app_user.dart` - User model with onboarding flags
- `lib/providers/auth_provider.dart` - Authentication and user management
- `lib/main.dart` - Navigation logic
- `lib/models/user.dart` - UserRole enum definition

## Notes

- Onboarding is mandatory for new users
- Cannot skip or bypass
- Role can be changed later in settings (future feature)
- All animations are optimized for performance
- Supports both light and dark mode (future enhancement)
