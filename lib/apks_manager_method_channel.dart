import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'apks_manager_platform_interface.dart';

/// An implementation of [ApksManagerPlatform] that uses method channels.
class MethodChannelApksManager extends ApksManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('apks_manager');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
