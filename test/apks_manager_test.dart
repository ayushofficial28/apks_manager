import 'package:flutter_test/flutter_test.dart';
import 'package:apks_manager/apks_manager.dart';
import 'package:apks_manager/apks_manager_platform_interface.dart';
import 'package:apks_manager/apks_manager_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockApksManagerPlatform
    with MockPlatformInterfaceMixin
    implements ApksManagerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ApksManagerPlatform initialPlatform = ApksManagerPlatform.instance;

  test('$MethodChannelApksManager is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelApksManager>());
  });

  test('getPlatformVersion', () async {
    ApksManager apksManagerPlugin = ApksManager();
    MockApksManagerPlatform fakePlatform = MockApksManagerPlatform();
    ApksManagerPlatform.instance = fakePlatform;

    expect(await apksManagerPlugin.getPlatformVersion(), '42');
  });
}
