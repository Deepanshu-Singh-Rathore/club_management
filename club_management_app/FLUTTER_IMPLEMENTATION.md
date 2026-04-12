# Flutter App Implementation Guide

## Overview
This Flutter app provides a complete Club Management client with role-based access for Students, Club Heads, and Admins.

## Architecture

### 1. **Core Layer** (`lib/core/`)
- **constants.dart** - App-wide constants (API endpoints, colors, storage keys)
- **api_service.dart** - Dio-based HTTP client with JWT token management and interceptors
- **theme.dart** - Material 3 theme with custom colors (#1565C0 primary, #7B61FF accent)
- **routes.dart** - Named route configuration

### 2. **Models Layer** (`lib/models/`)
All models include `fromJson()` and `toJson()` for backend serialization:
- **user.dart** - User model (id, fullName, email, phoneNumber, rollNumber, role, points, isVerified, createdAt)
- **club.dart** - Club model with pending requests tracking
- **join_request.dart** - Join request with status (pending/approved/rejected)
- **event.dart** - Event model with participant count
- **event_registration.dart** - Event registration with status field
- **auth_response.dart** - Login response with tokens and user data

### 3. **Provider Layer** (`lib/providers/`)
State management using Provider 6.0.0:

#### AuthProvider
- Manages login, registration, logout, token refresh
- Persists tokens to SharedPreferences automatically
- Auto-loads saved session on app start
- Provides: `isAuthenticated`, `currentUser`, `userRole`, `isLoading`, `error`
- Role helpers: `isStudent`, `isClubHead`, `isAdmin`

#### ClubProvider
- List of clubs from API
- Create club (admin only)
- Select individual club

#### JoinRequestProvider
- List of join requests with status-based filtering
- Send join request (student)
- Approve/reject requests (club head)
- Helper: `getUserRequestStatus(clubId))`

#### EventProvider
- List events (with optional club filter)
- Create event (club head)
- Register for event (student)
- Get event participants (club head)

### 4. **Screens Layer** (`lib/screens/`)

#### Authentication Screens
- **splash_screen.dart** - 2-second splash with auth state checking
- **login_screen.dart** - Email/password login with validation and error display
- **registration_screen.dart** - Student registration with email validation

#### Role-Based Home Screens
- **student_home_screen.dart**
  - Tabs: Clubs, My Requests, Events, Registrations
  - Features: Browse clubs, track join requests, view events
  
- **club_head_home_screen.dart**
  - Tabs: My Clubs, Pending Requests, Events, Participants
  - Features: Manage clubs, approve/reject requests, create events
  
- **admin_home_screen.dart**
  - Tabs: All Clubs, Users, Events, Leaderboard
  - Features: Club management, user oversight, system statistics

## API Integration Points

### Authentication Flow
1. User enters email/password on LoginScreen
2. AuthProvider calls ApiService.login()
3. ApiService uses Dio to POST to `/api/login/`
4. Backend returns AccessToken, RefreshToken, User, Role
5. AuthProvider saves tokens to SharedPreferences
6. App navigates to role-based home screen

### API Service Features
- **Base URL:** Configurable in AppConstants.baseUrl
- **JWT Interceptor:** Automatically adds Bearer token to all requests
- **Token Refresh:** Handles expired tokens transparently
- **Typed Responses:** All methods return strongly-typed models
- **Error Handling:** DioException caught and re-thrown for Provider error display

### Endpoints Implemented
```
Authentication:
  POST /api/register/
  POST /api/login/
  POST /api/refresh/
  GET  /api/me/
  GET  /api/leaderboard/

Clubs:
  GET    /api/clubs/
  POST   /api/clubs/  (admin only)
  GET    /api/clubs/{id}/

Join Requests:
  GET    /api/join-requests/
  POST   /api/join-requests/
  POST   /api/join-requests/{id}/approve/
  POST   /api/join-requests/{id}/reject/

Events:
  GET    /api/events/
  POST   /api/events/
  GET    /api/events/{id}/
  POST   /api/events/{id}/register/
  GET    /api/events/{id}/participants/
```

## Navigation Flow

```
SplashScreen (2 sec)
    ↓
[Check AuthProvider.isAuthenticated]
    ├─ Token Valid → Role-Based Screen
    │   ├─ Student → StudentHomeScreen
    │   ├─ ClubHead → ClubHeadHomeScreen
    │   └─ Admin → AdminHomeScreen
    └─ No Token → LoginScreen
        ├─ Register Link → RegistrationScreen
        └─ Login Success → Role-Based Screen
```

## Usage Examples

### Login Flow
```dart
final authProvider = context.read<AuthProvider>();
await authProvider.login(
  email: 'student@example.com',
  password: 'password123',
);
// User navigates automatically to role-based screen
```

### Fetch Clubs (with loading state)
```dart
Consumer<ClubProvider>(
  builder: (context, clubProvider, _) {
    if (clubProvider.isLoading) {
      return CircularProgressIndicator();
    }
    return ListView(
      children: clubProvider.clubs
        .map((club) => Text(club.name))
        .toList(),
    );
  },
)
```

### Send Join Request
```dart
final joinRequestProvider = context.read<JoinRequestProvider>();
await joinRequestProvider.sendJoinRequest(clubId);
```

## Configuration

### Update Backend URL
Edit `lib/core/constants.dart`:
```dart
// For Android emulator (default)
static const String baseUrl = 'http://10.0.2.2:8000/api';

// For iOS simulator
// static const String baseUrl = 'http://127.0.0.1:8000/api';

// For physical device (get your PC's IP)
// static const String baseUrl = 'http://192.168.x.x:8000/api';
```

### Theme Customization
Edit `lib/core/theme.dart` and `lib/core/constants.dart`:
```dart
class AppColors {
  static const int primaryColor = 0xFF1565C0;  // Change primary color
  static const int accentColor = 0xFF7B61FF;   // Change accent color
}
```

## Feature Implementations

### ✅ Complete
- Authentication (register/login/logout)
- JWT token management with auto-refresh
- Role-based routing and permissions
- Club browsing and joining (student)
- Join request management (club head)
- Event creation (club head)
- Event registration (student)
- Leaderboard data fetching (admin)
- Theme with Material 3

### 🔄 To Implement
- User profile editing
- Event details and participation tracking
- Club management interface (admin)
- Leaderboard UI (admin)
- OTP verification (optional)
- Search and filtering
- Notifications (push/local)
- Offline support with caching
- Dark mode complete styling

## Dependencies
- **flutter**: 3.0+
- **provider**: 6.0.0 (state management)
- **dio**: 5.4.0 (HTTP client)
- **shared_preferences**: 2.3.2 (local storage)
- **http**: 1.2.2 (included, fallback)
- **intl**: 0.19.0 (internationalization)
- **cupertino_icons**: 1.0.8 (iOS icons)

## Debugging

### API Issues
- Check `AppConstants.baseUrl` matches backend server
- Verify token is included in requests (Dio interceptor logs)
- Test endpoints with Postman/Insomnia

### Navigation Issues
- Ensure all routes in `AppRoutes.getRoutes()` map correctly
- Check `SplashScreen._navigateToRoleHome()` role handling
- Verify `MultiProvider` initialization order

### State Management Issues
- Use `context.read<ProviderName>()` for one-time actions
- Use `Consumer<ProviderName>()` for reactive UI updates
- Check Provider initialization in `main.dart`

## Testing

### Test Login Flow
1. Clear app data/cache
2. Navigate to LoginScreen
3. Enter test credentials (from backend test data)
4. Verify navigation to correct role screen
5. Check user info displays correctly

### Test API Calls
1. Enable Dio logging in `api_service.dart`
2. Use Chrome DevTools with Flutter extension
3. Monitor network requests in Postman/Insomnia
4. Verify token persistence in SharedPreferences

## Security Considerations
- Tokens stored in SharedPreferences (device-specific, not extractable)
- Bearer token sent only over network (no logging)
- Password validation on both client and server
- JWT expiry enforced server-side
- Role-based access enforced server-side (client UI is filtered)

