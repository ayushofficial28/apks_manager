
import 'apks_manager_platform_interface.dart';

class ApksManager {
  Future<String?> getPlatformVersion() {
    return ApksManagerPlatform.instance.getPlatformVersion();
  }
}
