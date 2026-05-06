#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import AppKit
#endif

import AuthenticationServices

public class BiometricStoragePlugin: NSObject, FlutterPlugin {
    
    private var passkeyImpl: Any? // Store reference to prevent deallocation
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let channel = FlutterMethodChannel(name: "webauthn_secure_storage", binaryMessenger: registrar.messenger())
        let instance = BiometricStoragePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        #elseif os(macOS)
        let channel = FlutterMethodChannel(name: "webauthn_secure_storage", binaryMessenger: registrar.messenger)
        let instance = BiometricStoragePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        #endif
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 16.0, macOS 12.0, *) {
            let impl = passkeyImpl as? PasskeyImplementation ?? PasskeyImplementation()
            passkeyImpl = impl
            
            if call.method == "registerPasskey" {
                if let args = call.arguments as? [String: Any], let options = args["options"] as? [String: Any] {
                    impl.registerPasskey(options: options, result: result)
                } else {
                    result(FlutterError(code: "InvalidArguments", message: "Invalid options", details: nil))
                }
                return
            } else if call.method == "authenticateWithPasskey" {
                if let args = call.arguments as? [String: Any], let options = args["options"] as? [String: Any] {
                    impl.authenticateWithPasskey(options: options, result: result)
                } else {
                    result(FlutterError(code: "InvalidArguments", message: "Invalid options", details: nil))
                }
                return
            }
        }
        
        let target = BiometricStorageImpl(result: result)
        BiometricStorageImpl.handleMethodCall(call, target: target)
    }
}
