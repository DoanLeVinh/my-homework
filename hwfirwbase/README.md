# SmartTasks - Firebase Authentication Flutter App

A comprehensive Flutter application demonstrating Firebase authentication with multiple sign-in methods: Google, Email/Password, and Phone/SMS.

## Features

- ✅ **Google Sign-In** - OAuth authentication with Google accounts
- ✅ **Email/Password Authentication** - Sign up and sign in with email credentials
- ✅ **Phone/SMS Authentication** - Verify users via phone numbers with SMS codes
- ✅ **User Profile Management** - View and edit user information with Firestore persistence
- ✅ **Form Validation** - Email format, password length, and phone number validation
- ✅ **Loading States** - Visual feedback during authentication operations
- ✅ **Error Handling** - User-friendly error messages for all auth scenarios

## Screenshots

### Login Screen
- Custom logo display
- Google Sign-In button with loading indicator
- Email and Phone authentication options
- Clean, modern UI with blue theme (#2E7DF7)

### Profile Screen
- User avatar with camera icon overlay
- Editable name field
- Read-only email display
- Date of Birth picker
- Save Profile and Save & Sign Out buttons
- Firestore integration for data persistence

## Prerequisites

- **Flutter SDK**: 3.32.8 or higher
- **Dart SDK**: 3.8.1 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Project** with Authentication and Firestore enabled
- **Android NDK**: 27.0.12077973 (automatically configured)

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enter your project name (e.g., "mobile-app-88641")
4. Complete the project creation

### 2. Enable Authentication Methods

In Firebase Console:
1. Navigate to **Authentication** > **Sign-in method**
2. Enable the following providers:
   - **Google** - Click Enable and configure
   - **Email/Password** - Click Enable
   - **Phone** - Click Enable and add test phone numbers if needed

### 3. Add Android App to Firebase

1. In Firebase Console, click **Add app** > **Android**
2. Enter your package name: `com.example.hwfirwbase`
3. Enter app nickname (optional): "SmartTasks Android"
4. Click **Register app**

### 4. Configure SHA-1 Certificate

Firebase requires your app's SHA-1 fingerprint for Google Sign-In:

#### Get SHA-1 Fingerprint:

```powershell
# Navigate to android directory
cd android

# Run signing report (Windows PowerShell)
.\gradlew signingReport

# OR on Mac/Linux
./gradlew signingReport
```

Look for the **SHA-1** under `Variant: debug` > `Config: debug`:
```
SHA1: 8E:EE:49:8E:46:B9:DA:46:8B:67:2C:55:47:83:A7:C3:81:26:3B:B7
```

#### Add SHA-1 to Firebase:

1. In Firebase Console, go to **Project Settings** > **Your apps** > **Android app**
2. Scroll to **SHA certificate fingerprints**
3. Click **Add fingerprint**
4. Paste your SHA-1 value
5. Click **Save**

### 5. Download google-services.json

1. In Firebase Console, go to **Project Settings**
2. Under **Your apps**, find your Android app
3. Click **Download google-services.json**
4. Place the file in `android/app/google-services.json`

**Important**: The `google-services.json` must include OAuth client entries with your SHA-1 certificate hash.

### 6. Enable Firestore Database

1. In Firebase Console, navigate to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (or production mode with security rules)
4. Select a location for your database
5. Click **Enable**

## Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd hwfirwbase
```

### 2. Install Dependencies

```powershell
flutter pub get
```

### 3. Configure Firebase

Ensure `android/app/google-services.json` is in place with your Firebase configuration.

### 4. Run the App

```powershell
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# OR run in release mode
flutter run --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point, Firebase initialization
├── images/
│   └── Logo.png                 # App logo asset
└── screens/
    ├── login_screen.dart        # Authentication screen with 3 sign-in methods
    └── profile_screen.dart      # User profile with Firestore integration

android/
├── app/
│   ├── build.gradle.kts         # Android app-level Gradle config
│   └── google-services.json     # Firebase configuration (required)
└── build.gradle.kts             # Project-level Gradle config
```

## Usage

### Google Sign-In

1. Tap **"SIGN IN WITH GOOGLE"** button
2. Select your Google account
3. Grant permissions
4. Redirected to Profile screen

### Email/Password Sign-In

1. Tap **"Sign in with Email"** text button
2. Enter email and password
3. Choose **"Sign up"** (new user) or **"Sign in"** (existing user)
4. Validation ensures:
   - Email format is valid
   - Password is at least 6 characters
5. Redirected to Profile screen on success

### Phone/SMS Sign-In

1. Tap **"Sign in with Phone"** text button
2. Enter phone number with country code (e.g., `+84123456789`)
3. Tap **"Send code"**
4. Enter the 6-digit verification code received via SMS
5. Tap **"Verify"**
6. Redirected to Profile screen

#### Testing Phone Authentication

For testing without SMS:
1. In Firebase Console > Authentication > Sign-in method > Phone
2. Add test phone numbers (e.g., `+1 650-555-1234` with code `123456`)
3. Use these in development without consuming SMS quota

### Profile Management

In Profile screen:
- **Name**: Tap to edit, changes saved to Firestore
- **Email**: Read-only, displays authenticated email
- **Date of Birth**: Tap to select from date picker
- **Save Profile**: Saves changes to Firestore
- **Save & Sign Out**: Saves and returns to login screen

## Dependencies

Core packages (in `pubspec.yaml`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^4.2.0           # Firebase SDK initialization
  firebase_auth: ^6.1.1           # Authentication functionality
  google_sign_in: ^7.2.0          # Google OAuth integration
  firebase_analytics: ^12.0.3     # Analytics (optional)
  cloud_firestore: ^6.0.3         # Firestore database
```

## Troubleshooting

### Google Sign-In Fails

**Error**: `PlatformException(sign_in_failed, ...)`

**Solution**:
1. Verify SHA-1 is added to Firebase Console
2. Check package name matches: `com.example.hwfirwbase`
3. Ensure `google-services.json` has OAuth client with matching SHA-1
4. Clean and rebuild:
   ```powershell
   flutter clean
   flutter pub get
   cd android
   .\gradlew clean
   cd ..
   flutter run
   ```

### Phone Sign-In Not Working

**Error**: SMS not received or verification fails

**Solution**:
1. Check Phone authentication is enabled in Firebase Console
2. Use test phone numbers for development (see Firebase Console)
3. Ensure phone number format includes country code (e.g., `+84...`)
4. Check Firebase project quota limits

### Build Errors

**Error**: `google-services.json not found`

**Solution**:
- Download from Firebase Console and place in `android/app/`

**Error**: NDK version mismatch

**Solution**:
- Already configured in `android/app/build.gradle.kts`: `ndkVersion = "27.0.12077973"`

### Firestore Permission Denied

**Error**: `PERMISSION_DENIED: Missing or insufficient permissions`

**Solution**:
Update Firestore security rules in Firebase Console:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Building for Release

### Android APK

```powershell
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```powershell
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

**Note**: For production releases, configure proper signing keys in `android/app/build.gradle.kts`.

## Testing

Run analyzer to check for code issues:

```powershell
flutter analyze
```

Run unit/widget tests:

```powershell
flutter test
```

## Configuration Details

### Package Name
- **Android**: `com.example.hwfirwbase` (in `android/app/build.gradle.kts`)
- **iOS**: `com.example.hwfirwbase` (in `ios/Runner/Info.plist`)

### Firebase Project
- **Project ID**: mobile-app-88641
- **Authentication**: Google, Email/Password, Phone
- **Firestore**: users collection with name, email, dob fields

### App Theme
- **Primary Color**: #2E7DF7 (Blue)
- **Background**: White
- **Accent**: Light Blue (#E7F0FE)

## Known Issues

- Google Sign-In requires physical device or emulator with Google Play Services
- Phone authentication may not work in some emulators (use physical device)
- Initial Firestore load may be slow on first app launch

## License

This project is created for educational purposes as part of a Flutter homework assignment.

## Author

Created with Firebase Authentication best practices and Flutter 3.32.8.

---

**Last Updated**: November 1, 2025
