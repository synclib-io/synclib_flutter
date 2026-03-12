import Flutter
import UIKit

// Dummy function to force linking of synclib C library
@_silgen_name("synclib_open")
func synclib_open(_: UnsafePointer<CChar>, _: UnsafeMutablePointer<OpaquePointer?>) -> Int32

public class SynclibFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "synclib_flutter", binaryMessenger: registrar.messenger())
    let instance = SynclibFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Dummy reference to ensure synclib symbols are linked
    let _ = synclib_open
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
