import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'apks_manager_platform_interface.dart';

class ApksManager {
  
  
  /// - [baseApkPath]: Path to the app's base.apk
  /// - [appName]: The name of the app (used for filename)
  /// - [outputDirPath]: (Optional) Where to save the file. Defaults to system temp directory.
  /// - [extension]: (Optional) Custom file extension (e.g., 'xapk'). Defaults to 'apks'.
  static Future<String?> createBundle({
    required String baseApkPath,
    required String appName,
    String? outputDirPath,
    String extension = 'apks',
  }) async {
    try {
      // Setup the destination path before jumping into the background thread
      final saveDir = outputDirPath ?? Directory.systemTemp.path;
      final cleanExt = extension.startsWith('.') ? extension.substring(1) : extension;
      final bundleFilePath = '$saveDir/$appName.$cleanExt';

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
        encoder.create(bundleFilePath);

        for (final apk in apkFiles) {
          encoder.addFile(apk);
        }
        encoder.close();

        return bundleFilePath; 
      });
      
    } catch (e) {
      print("Error creating bundle: $e");
      return null;
    }
  }

  /// Installs a bundle file (e.g., .apks, .xapk) by extracting the APKs and passing them to the native installer.
  static Future<bool> installBundle(String bundleFilePath) async {
    try {
      final file = File(bundleFilePath);
      if (!file.existsSync()) {
        print("Error: Bundle file does not exist at $bundleFilePath");
        return false;
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
      print("Error installing bundle: $e");
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
      print("BhejDe cache cleaned successfully.");
    } catch (e) {
      print("Error cleaning temp directory: $e");
    }
  }
}