import 'package:flutter/material.dart';
import 'package:apks_manager/apks_manager.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:file_picker/file_picker.dart';

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
      title: 'APKs Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isInstalling = false;

  String _statusMessage = 'Loading installed apps...';

  String? _bundlePath;
  List<AppInfo> _installedApps = [];

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading installed apps...';
    });

    try {
      final apps = await FlutterDeviceApps.listApps(
        includeSystem: false,
        onlyLaunchable: true,
        includeIcons: true,
      );

      if (!mounted) return;

      setState(() {
        _installedApps = apps;
        _statusMessage = 'Select an app to create a bundle';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Failed to load installed apps';
      });
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createBundle(AppInfo app) async {
    if (app.apkPath == null) {
      _showMessage(
        'APK path is unavailable for ${app.appName ?? 'this app'}',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating bundle for ${app.appName}...';
    });

    try {
      final path = await ApksManager.createBundle(
        baseApkPath: app.apkPath!,
        appName: (app.appName ?? 'app').replaceAll(' ', '_'),
        outputDirPath: '/storage/emulated/0/Download',
        extension: 'apks',
      );

      if (!mounted) return;

      setState(() {
        _bundlePath = path;
        _statusMessage = path != null
            ? 'Bundle created successfully'
            : 'Failed to create bundle';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Failed to create bundle';
      });

      _showMessage(
        'Error creating bundle: $e',
        isError: true,
      );
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _installBundle() async {
    if (_isInstalling) return;

    try {
      final result = await FilePicker.platform.pickFiles(
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final path = result.files.single.path!;

      if (!mounted) return;

      setState(() {
        _isInstalling = true;
        _statusMessage = 'Preparing installation...';
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      );

      if (!mounted) return;

      setState(() {
        _statusMessage =
            'Installation in progress...\n'
            'Please wait until the installation finishes.';
      });

      // IMPORTANT:
      //
      // This Future remains pending while Ackpine is installing.
      //
      // It only completes when:
      //   true  -> installation succeeded
      //   false -> installation failed (depending on plugin API)
      //
      // Native confirmation disappearing does NOT complete this Future.
      final success = await ApksManager.installBundle(path);

      if (!mounted) return;

      if (success) {
        setState(() {
          _statusMessage =
              'Installation completed successfully!';
        });

        _showMessage(
          'Installation completed successfully',
        );
      } else {
        setState(() {
          _statusMessage = 'Installation failed';
        });

        _showMessage(
          'Installation failed',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Installation failed';
      });

      _showMessage(
        'Error installing bundle: $e',
        isError: true,
      );
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  Widget _buildStatusCard() {
    final bool isSuccess =
        _statusMessage.toLowerCase().contains('successfully');

    final bool isError =
        _statusMessage.toLowerCase().contains('failed');

    IconData icon;

    if (_isInstalling) {
      icon = Icons.install_mobile;
    } else if (isSuccess) {
      icon = Icons.check_circle;
    } else if (isError) {
      icon = Icons.error;
    } else {
      icon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isInstalling)
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              )
            else
              Icon(
                icon,
                size: 28,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppList() {
    if (_installedApps.isEmpty) {
      return const Center(
        child: Text(
          'No launchable apps found',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _installedApps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final app = _installedApps[index];

        final iconBytes = app.iconBytes;

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: iconBytes != null
                  ? Image.memory(
                      iconBytes,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.android,
                        size: 36,
                      ),
                    ),
            ),
            title: Text(
              app.appName ?? 'Unknown App',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              app.packageName ?? 'Unknown Package',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: FilledButton(
              onPressed:
                  _isLoading || _isInstalling
                      ? null
                      : () => _createBundle(app),
              child: const Text('Bundle'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBundleCard() {
    if (_bundlePath == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bundle ready',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _bundlePath!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APKs Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.install_mobile),
            tooltip: 'Install APK bundle',
            onPressed:
                _isInstalling ? null : _installBundle,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh apps',
            onPressed:
                _isLoading || _isInstalling
                    ? null
                    : _loadInstalledApps,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                _buildStatusCard(),

                Expanded(
                  child: _buildAppList(),
                ),

                _buildBundleCard(),
              ],
            ),
      
    );
  }
}