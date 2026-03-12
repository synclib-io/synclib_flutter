import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'synclib_flutter_platform_interface.dart';

/// An implementation of [SynclibFlutterPlatform] that uses method channels.
class MethodChannelSynclibFlutter extends SynclibFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('synclib_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
