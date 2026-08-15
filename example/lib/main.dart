import 'package:flutter/material.dart';
import 'package:apks_manager/apks_manager.dart';
import 'package:file_picker/file_picker.dart'; // Or your document fetcher plugin

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApksManager.cleanUpTempDirectory();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Apks Manager Example')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // Dynamically pick a file using a picker instead of hardcoding
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.any,
                    );

                    if (result != null && result.files.single.path != null) {
                      String selectedPath = result.files.single.path!;
                      
                      String? bundlePath = await ApksManager.createBundle(
                        baseApkPath: selectedPath,
                        appName: "TestApp",
                        extension: "bhejde",
                      );
                      print("Bundle created at: $bundlePath");
                    }
                  },
                  child: const Text('Select APK & Create Bundle'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Pick a .bhejde or .apks file to test installation
                    FilePickerResult? result = await FilePicker.platform.pickFiles();

                    if (result != null && result.files.single.path != null) {
                      String bundlePath = result.files.single.path!;
                      
                      bool success = await ApksManager.installBundle(bundlePath);
                      print("Installation triggered: $success");
                    }
                  },
                  child: const Text('Select & Install Bundle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}