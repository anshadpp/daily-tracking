# Daily Tracker (Flutter, Android, fully offline)

Tracks the 13-block daily schedule. SQLite storage, local notifications, charts.

## First-time setup (Windows PowerShell)

```powershell
cd C:\Users\ansha\daily_tracker

# Generate android/, gradle, etc. (won't overwrite existing pubspec.yaml or lib/)
flutter create --project-name daily_tracker --platforms android .

flutter pub get
```

Then open `android/app/src/main/AndroidManifest.xml` and add these permissions
inside `<manifest>` (above `<application>`):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

And inside `<application>`, add the FLN receivers:

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

In `android/app/build.gradle` ensure:

- `compileSdkVersion 34` (or higher)
- `minSdkVersion 21` (or higher)
- `coreLibraryDesugaringEnabled true` under `compileOptions`
- Add `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'`
  to `dependencies`

## Run

Connect an Android device (USB debugging on) or start an emulator, then:

```powershell
flutter run
```

To build a release APK you can sideload:

```powershell
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk
```

## Features

- **Today** tab — checklist for the active day; current block highlighted; long-press a card to add a note.
- **History** tab — last 30 days with per-day completion %; tap to jump back.
- **Stats** tab — 7/14/30-day bar chart, per-block completion frequency, streak.
- **Edit blocks** (gear icon, top-right) — add/edit/delete blocks, toggle reminders per block.
- **Reminders** — local notifications fire at the start of each block. Bell icon reschedules them.
- **Fully offline** — all data in SQLite on device.

## Customizing the default schedule

Edit `lib/db/default_blocks.dart` BEFORE the first run (default blocks are
seeded only when the DB is first created). To re-seed, uninstall the app
or clear its data, then reinstall.
