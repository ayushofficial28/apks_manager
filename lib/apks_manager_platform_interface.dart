import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'apks_manager_method_channel.dart';

abstract class ApksManagerPlatform extends PlatformInterface {
  /// Constructs a ApksManagerPlatform.
  ApksManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ApksManagerPlatform _instance = MethodChannelApksManager();

  /// The default instance of [ApksManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelApksManager].
  static ApksManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ApksManagerPlatform] when
  /// they register themselves.
  static set instance(ApksManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> installSplitApks(List<String> filePaths) {
    throw UnimplementedError('installSplitApks() has not been implemented.');
  }
}
