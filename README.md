# apks_manager

A Flutter plugin for Android that bundles single or split APKs into a custom-extended archive (e.g., `.apks`, `.xapk`, or any custom file extension) and triggers atomic installations natively using **Ackpine**.

## Features

* **Universal Packaging:** Automatically detects and bundles `base.apk` alongside any split feature/configuration APKs.
* **Custom Extensions:** Package files with any custom extension you want (`.apks`, `.xapk`, `.custom`, etc.).
* **Non-Blocking Performance:** Heavy zipping and unzipping operations run on background isolates using `Isolate.run()`, ensuring the Flutter UI remains responsive.
* **Native Ackpine Integration:** Reliable Android installation handling with safe system installation prompts through `ActivityAware`.
* **Automatic Cache Management:** Built-in utilities for cleaning temporary extracted files and keeping the device's storage footprint clean.

## Installation

Add `apks_manager` to your package's `pubspec.yaml`:

```yaml
dependencies:
  apks_manager:
    path: ../apks_manager # Or your pub.dev reference
```

Then run:

```bash
flutter pub get
```

## Android Configuration

Ensure your application's **`android/app/src/main/AndroidManifest.xml`** includes the package installation permission:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Required to trigger the system installation prompt -->
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />

</manifest>
```

> **Note:** Android may require the user to allow your application to install unknown apps before the installation prompt can be displayed.

## Usage

### 1. Cache Maintenance

It is recommended to clear residual temporary extraction files when your application starts:

```dart
import 'package:flutter/material.dart';
import 'package:apks_manager/apks_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean up leftover temporary extracted files from previous sessions
  ApksManager.cleanUpTempDirectory();

  runApp(const MyApp());
}
```

### 2. Create a Bundle

Package an application's APKs into a single archive with a custom extension:

```dart
import 'package:apks_manager/apks_manager.dart';

Future<void> generateBundle(String baseApkPath) async {
  // Creates an archive file with the specified extension
  final String? bundlePath = await ApksManager.createBundle(
    baseApkPath: baseApkPath,
    appName: 'TargetApp',
    extension: 'apks', // Optional: defaults to 'apks'
    compressionLevel: 0, // Optional: defaults to 0 (no compression)
  );

  if (bundlePath != null) {
    print('Bundle successfully created at: $bundlePath');
  }
}
```

The plugin automatically detects the application's `base.apk` and associated split APKs when creating the bundle.

For example:

```text
base.apk
split_config.arm64_v8a.apk
split_config.xxhdpi.apk
split_config.en.apk
```

can be packaged into:

```text
TargetApp.apks
```

You can also use any custom extension:

```dart
extension: 'bhejde'
```

which produces:

```text
TargetApp.bhejde
```

### 3. Extract and Install

On the receiving device, pass the bundle path directly to the installer:

```dart
import 'package:apks_manager/apks_manager.dart';

Future<void> installArchive(String bundleFilePath) async {
  // Works with .apks, .xapk, .zip, or custom extensions
  final bool success = await ApksManager.installBundle(bundleFilePath);

  if (success) {
    print('System installation prompt successfully triggered.');
  } else {
    print('Failed to start installation.');
  }
}
```

The extension of the archive does not need to be `.apks`. For example, all of the following can be passed to `installBundle()`:

```text
TargetApp.apks
TargetApp.xapk
TargetApp.zip
TargetApp.bhejde
TargetApp.custom
```

The bundle is extracted and the contained APK set is passed to the native Android installation flow through **Ackpine**.



## API

### `createBundle()`

Creates a single archive containing the application's base APK and associated split APKs.

```dart
ApksManager.createBundle(
  baseApkPath: baseApkPath,
  appName: 'TargetApp',
  extension: 'apks',
);
```

**Parameters:**

| Parameter     | Type     | Description                                   |
| ------------- | -------- | --------------------------------------------- |
| `baseApkPath` | `String` | Path to the application's `base.apk`.         |
| `appName`     | `String` | Name used for the generated archive.          |
| `extension`   | `String` | Custom archive extension. Defaults to `apks`. |

**Returns:**

```dart
Future<String?>
```

Returns the generated bundle path, or `null` if bundle creation fails.

### `installBundle()`

Extracts the supplied archive and starts the native Android installation process.

```dart
final bool success = await ApksManager.installBundle(bundleFilePath);
```

**Parameters:**

| Parameter        | Type     | Description                      |
| ---------------- | -------- | -------------------------------- |
| `bundleFilePath` | `String` | Path to the received APK bundle. |

**Returns:**

```dart
Future<bool>
```

Returns `true` when the installation process was successfully triggered, otherwise `false`.

### `cleanUpTempDirectory()`

Removes temporary files created during bundle extraction.

```dart
ApksManager.cleanUpTempDirectory();
```

It is recommended to call this during application startup.

## Performance

APK archives can contain large files, so compression and extraction are performed outside the main Flutter UI isolate using Dart's `Isolate.run()`.

This prevents lengthy file operations from blocking the UI and helps avoid **Application Not Responding (ANR)** issues when handling large APK files on physical devices.

## Requirements

* Android
* Flutter
* Android application with permission to request package installations
* User approval for installing unknown apps, where required by Android

## License

Distributed under the **MIT License**.

See the [`LICENSE`](LICENSE) file for more information.
