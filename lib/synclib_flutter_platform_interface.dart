import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'synclib_flutter_method_channel.dart';

abstract class SynclibFlutterPlatform extends PlatformInterface {
  /// Constructs a SynclibFlutterPlatform.
  SynclibFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static SynclibFlutterPlatform _instance = MethodChannelSynclibFlutter();

  /// The default instance of [SynclibFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelSynclibFlutter].
  static SynclibFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SynclibFlutterPlatform] when
  /// they register themselves.
  static set instance(SynclibFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
