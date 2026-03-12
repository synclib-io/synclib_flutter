import 'package:flutter_test/flutter_test.dart';
import 'package:synclib_flutter/synclib_flutter.dart';
import 'package:synclib_flutter/synclib_flutter_platform_interface.dart';
import 'package:synclib_flutter/synclib_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSynclibFlutterPlatform
    with MockPlatformInterfaceMixin
    implements SynclibFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SynclibFlutterPlatform initialPlatform = SynclibFlutterPlatform.instance;

  test('$MethodChannelSynclibFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSynclibFlutter>());
  });

  test('getPlatformVersion', () async {
    SynclibFlutter synclibFlutterPlugin = SynclibFlutter();
    MockSynclibFlutterPlatform fakePlatform = MockSynclibFlutterPlatform();
    SynclibFlutterPlatform.instance = fakePlatform;

    expect(await synclibFlutterPlugin.getPlatformVersion(), '42');
  });
}
