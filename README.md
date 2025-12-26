# Kaalapatram - Flutter Firebase Authentication App

A production-ready Flutter mobile app with Firebase Authentication using email/password login.

## Features

- **Splash Screen**: Animated logo with authentication state check
- **Login Screen**: Email/password authentication with validation
- **Register Screen**: User registration with password confirmation
- **Home Page**: Dashboard for authenticated users
- **Firebase Integration**: Complete Firebase Authentication setup
- **Modern UI**: Material 3 design with rounded corners and modern styling
- **Input Validation**: Comprehensive form validation
- **Error Handling**: User-friendly error messages from Firebase
- **Null Safety**: Full null safety compliance

## Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── screens/
│   ├── splash_screen.dart   # Animated splash screen with auth check
│   ├── login_screen.dart    # Email/password login form
│   ├── register_screen.dart # User registration form
│   └── home_page.dart       # Dashboard for authenticated users
├── services/
│   └── auth_service.dart    # Firebase Authentication wrapper
└── widgets/                 # Reusable UI components (future use)
```

## Setup Instructions

### Prerequisites

1. Flutter SDK (3.6.0 or higher)
2. Firebase project with Authentication enabled
3. `google-services.json` file for Android (already assumed to be configured)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd kaalapatram
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Ensure `google-services.json` is placed in `android/app/`
   - Firebase project should have Email/Password authentication enabled

4. **Run the app**
   ```bash
   flutter run
   ```

## Dependencies

- `firebase_core: ^3.6.0` - Firebase core functionality
- `firebase_auth: ^5.3.1` - Firebase Authentication

## Key Features

### Authentication Service (`lib/services/auth_service.dart`)
- Email/password sign in and registration
- Password reset functionality
- Comprehensive error handling with user-friendly messages
- Input validation utilities
- Auth state management

### UI Components
- **Splash Screen**: 2-second animated logo with auth state check
- **Login Screen**: Modern form with validation and forgot password
- **Register Screen**: Registration form with password confirmation
- **Home Page**: Dashboard with user info and feature cards

### Validation
- Email format validation
- Password strength requirements (minimum 6 characters)
- Password confirmation matching
- Non-empty field validation

### Error Handling
- Firebase Auth exception handling
- User-friendly error messages
- Network error handling
- Loading states with proper UI feedback

## Firebase Configuration

The app assumes Firebase is already configured with:
- `google-services.json` in `android/app/`
- Email/Password authentication enabled in Firebase Console
- Firebase project properly initialized

## Development

The app follows Flutter best practices:
- Clean architecture with separated concerns
- Null safety throughout
- Material 3 design system
- Responsive UI design
- Proper state management
- Error handling and user feedback

## Future Enhancements

- Email verification flow
- Social authentication (Google, Apple)
- Biometric authentication
- Remember me functionality
- User profile management
- Password strength indicator
- Dark mode support