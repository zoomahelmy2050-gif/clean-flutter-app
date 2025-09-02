# Google Sign-In Debug Guide

## Current Issue
Google Sign-In is failing with gralloc4 errors and activity lifecycle issues.

## Required Steps to Fix

### 1. Get SHA-1 Certificate Fingerprint
```bash
# For debug keystore
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Or using gradlew
cd android
./gradlew signingReport
```

### 2. Add SHA-1 to Firebase Console
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: hazem-a23a4
3. Go to Project Settings > General
4. Under "Your apps" find the Android app
5. Add the SHA-1 fingerprint from step 1

### 3. Download Updated google-services.json
After adding SHA-1, download the updated google-services.json and replace the current one.

### 4. Verify Package Name Match
Ensure the package name in:
- android/app/build.gradle.kts: `applicationId = "com.hazem.cleanflutter"`
- google-services.json: `"package_name": "com.hazem.cleanflutter"`

### 5. Clean and Rebuild
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk --debug
```

## Current Configuration Status
- ✅ Google Services plugin added to build.gradle.kts
- ✅ google-services.json exists with correct package name
- ❌ SHA-1 fingerprint likely missing from Firebase Console
- ✅ Internet permission added to AndroidManifest.xml

## Test Commands
```bash
# Check if Google Sign-In works
flutter run --debug

# Monitor logs
adb logcat | grep -i google
```
