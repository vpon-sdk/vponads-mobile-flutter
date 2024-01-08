import 'package:flutter_test/flutter_test.dart';
import 'package:vpon_plugin_poc/vpon_plugin_poc.dart';
import 'package:vpon_plugin_poc/vpon_plugin_poc_platform_interface.dart';
import 'package:vpon_plugin_poc/vpon_plugin_poc_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVponPluginPocPlatform
    with MockPlatformInterfaceMixin
    implements VponPluginPocPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VponPluginPocPlatform initialPlatform = VponPluginPocPlatform.instance;

  test('$MethodChannelVponPluginPoc is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVponPluginPoc>());
  });

  test('getPlatformVersion', () async {
    VponPluginPoc vponPluginPocPlugin = VponPluginPoc();
    MockVponPluginPocPlatform fakePlatform = MockVponPluginPocPlatform();
    VponPluginPocPlatform.instance = fakePlatform;

    expect(await vponPluginPocPlugin.getPlatformVersion(), '42');
  });
}
