## 1.1.1

* **Fixed**:
  * Resolved issue of `createBundle()` returning an empty zip file due to unawaited calls to addFile.

## 1.1.0

* **Added**:
  * Support for installing standalone `.apk` files through `installBundle()`.
  * `installBundle()` now supports both `.apk` files and APK bundles such as `.apks`.

## 1.0.0

* **Initial Release**:
  * Bundle split APK files into `.apks` archives with custom compression levels.
  * Optimized default store-only mode (`level: 0`) for rapid uncompressed installation and memory mapping.
  * Resilient file naming and collision handling across Android storage environments.
  * Added example app showcasing bundle creation and split APK installation.