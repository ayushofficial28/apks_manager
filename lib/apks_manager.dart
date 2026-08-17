import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'apks_manager_platform_interface.dart';

class ApksManager {
  
  
  /// - [baseApkPath]: Path to the app's base.apk
  /// - [appName]: The name of the app (used for filename)
  /// - [outputDirPath]: (Optional) Where to save the file. Defaults to system temp directory.
  /// - [extension]: (Optional) Custom file extension (e.g., 'xapk'). Defaults to 'apks'.
  /// - [compressionLevel]: (Optional) Compression level for the zip file (0-9). Defaults to 0 (no compression).
  static Future<String?> createBundle({
    required String baseApkPath,
    required String appName,
    String? outputDirPath,
    String extension = 'apks',
    int compressionLevel = 0
  }) async {
    try {
      // Setup the destination path before jumping into the background thread
      final saveDir = outputDirPath ?? Directory.systemTemp.path;
      final cleanExt = extension.startsWith('.') ? extension.substring(1) : extension;
      String bundleFilePath = '$saveDir/$appName.$cleanExt';
      int counter=1;
      // Offload the heavy directory scanning and zipping to a background Isolate
      return await Isolate.run(() {
        final Directory appDir = File(baseApkPath).parent;
        final List<FileSystemEntity> files = appDir.listSync();
        final List<File> apkFiles = [];

        for (final entity in files) {
          if (entity is File && entity.path.endsWith('.apk')) {
            apkFiles.add(entity);
          }
        }

        if (apkFiles.isEmpty) {
          throw Exception("No APK files found in directory.");
        }

        final encoder = ZipFileEncoder();
        while (true) {
          // Check 1: Files your app created (Visible to your app)
          // If your app made it, existsSync() returns true. 
          if (File(bundleFilePath).existsSync()) {
            bundleFilePath = '$saveDir/$appName($counter).$cleanExt';
            counter++;
            continue; // Skip the try-catch and test the new name
          }

          // Check 2: Files other apps created (Hidden by Scoped Storage)
          try {
            // If we reach here, existsSync() was false. 
            // If another app owns it, this line throws errno 17.
            // If no one owns it, it successfully creates the file.
            encoder.create(bundleFilePath, level: compressionLevel);
            break; 
          } catch (e) {
            // The OS rejected the write request. Update the path and loop again.
            bundleFilePath = '$saveDir/$appName($counter).$cleanExt';
            counter++;
          }
        }

        for (final apk in apkFiles) {
          encoder.addFile(apk);
        }
        encoder.close();

        return bundleFilePath; 
      });
      
    } catch (e) {
      debugPrint("Error creating bundle: $e");
      return null;
    }
  }

  /// Installs a bundle file (e.g., .apks, .xapk) by extracting the APKs and passing them to the native installer.
  /// Can also install .apk files directly
  static Future<bool> installBundle(String bundleFilePath) async {
    try {
      final file = File(bundleFilePath);
      if (!file.existsSync()) {
        debugPrint("Error: Bundle file does not exist at $bundleFilePath");
        return false;
      }
      if (bundleFilePath.endsWith('.apk')) {
      return await ApksManagerPlatform.instance
          .installSplitApks([bundleFilePath]);
      }

      // Offload the heavy file reading and unzipping to a background Isolate
      final extractedPaths = await Isolate.run(() {
        final bytes = file.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        final tempDirPath = 
            '${Directory.systemTemp.path}/extracted_apks_${DateTime.now().millisecondsSinceEpoch}';
        final tempDir = Directory(tempDirPath);
        tempDir.createSync(recursive: true);

        final List<String> paths = [];

        for (final archiveFile in archive) {
          // Only extract valid .apk files
          if (archiveFile.isFile && archiveFile.name.endsWith('.apk')) {
            final data = archiveFile.content as List<int>;
            final extractedFile = File('$tempDirPath/${archiveFile.name}');
            extractedFile.createSync(recursive: true);
            extractedFile.writeAsBytesSync(data);
            paths.add(extractedFile.path);
          }
        }
        
        return paths; // Pass the list of extracted file paths back to the Main Thread
      });

      // Back on the Main UI Thread: pass the paths to the Java bridge
      if (extractedPaths.isNotEmpty) {
        return await ApksManagerPlatform.instance.installSplitApks(extractedPaths);
      }
      
      return false;
    } catch (e) {
      debugPrint("Error installing bundle: $e");
      return false;
    }
  }

  /// Deletes all previously extracted APKs to free up storage space.
  /// Call this in your main.dart when the app starts up.
  static Future<void> cleanUpTempDirectory() async {
    try {
      // Run in background so it doesn't slow down app startup
      await Isolate.run(() {
        final tempDir = Directory(Directory.systemTemp.path);
        if (tempDir.existsSync()) {
          final List<FileSystemEntity> entities = tempDir.listSync();
          
          for (var entity in entities) {
            // Only delete folders that we created for extraction
            if (entity is Directory && entity.path.contains('extracted_apks_')) {
              entity.deleteSync(recursive: true);
            }
          }
        }
      });
      debugPrint("Bundle cache cleaned successfully.");
    } catch (e) {
      debugPrint("Error cleaning temp directory: $e");
    }
  }
}