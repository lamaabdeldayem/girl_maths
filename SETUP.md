# Fresh setup (Windows)

## 1. Install the tools (one time)
1. **Git**: https://git-scm.com/download/win (keep the default options).
2. **Android Studio**: https://developer.android.com/studio
   - First launch: choose *Standard* setup. This downloads the Android SDK and an emulator.
   - *More Actions → SDK Manager → SDK Tools*: tick **Android SDK Command-line Tools** → Apply.
   - *Plugins*: install **Flutter** (installs Dart too) → restart.
3. **Flutter SDK** (Dart comes inside it): https://docs.flutter.dev/get-started/install/windows
   - Unzip it to `C:\src\flutter`. Don't put it in `Program Files` or a path with spaces.
   - Add `C:\src\flutter\bin` to *Path* (Start → "Edit the system environment variables" → Environment Variables → Path → New).
4. Open a **new** terminal:
   ```
   flutter doctor
   flutter doctor --android-licenses     (press y for every licence)
   flutter doctor                        (everything for Android should be ✓)
   ```

## 2. Create the project
1. Unzip `girl_maths.zip` to e.g. `C:\dev\girl_maths` (path without spaces).
2. In that folder run:
   ```
   flutter create . --org com.girlmaths --project-name girl_maths --platforms android,ios
   ```
   This generates the `android/` and `ios/` folders. It does **not** overwrite `lib/`, `test/` or `pubspec.yaml`.
3. Small platform edits:
   - `android/app/src/main/AndroidManifest.xml`: add this line right under `<manifest ...>` (needed for Firebase in release builds):
     ```xml
     <uses-permission android:name="android.permission.INTERNET"/>
     ```
     and change `android:label="girl_maths"` to `android:label="Masroufi"`.
   - (Only if you build for iPhone) `ios/Runner/Info.plist`: add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` keys.

## 3. Check that it works
```
flutter pub get
flutter analyze
flutter test
flutter run          (with the emulator open or a phone plugged in with USB debugging)
```
Rotate the emulator (Ctrl + ← / →) to see the landscape layout.

## 4. New GitHub repository
1. github.com → **New repository** → name `girl_maths` → **don't** add a README, .gitignore or licence → Create.
2. In the project folder:
   ```
   git init
   git add .
   git commit -m "Masroufi: Assignment 2 (all phases)"
   git branch -M main
   git remote add origin https://github.com/<your-username>/girl_maths.git
   git push -u origin main
   ```
3. Teammates: repo → Settings → Collaborators → Add people.

## 5. Firebase (Phase 4)
1. console.firebase.google.com → Add project → *Build → Realtime Database → Create database* → **test mode**.
2. Copy the URL into `.env`:
   ```
   FIREBASE_DB_URL=https://<project>-default-rtdb.firebaseio.com
   ```
3. Restart the app (a full restart, not a hot reload). The cloud icon on Home turns green when it is synced.
