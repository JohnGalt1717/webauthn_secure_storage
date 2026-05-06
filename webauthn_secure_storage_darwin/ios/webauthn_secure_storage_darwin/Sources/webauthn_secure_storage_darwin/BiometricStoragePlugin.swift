import Flutter
import UIKit
import AuthenticationServices

public class BiometricStoragePlugin: NSObject, FlutterPlugin {

    private var passkeyImpl: Any? // Store reference to prevent deallocation
    
    private let impl = BiometricStorageImpl(storageError: { (code, message, details) -> Any in
      FlutterError(code: code, message: message, details: details)
    }, storageMethodNotImplemented: FlutterMethodNotImplemented)

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "webauthn_secure_storage", binaryMessenger: registrar.messenger())
        let instance = BiometricStoragePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            let passImpl = passkeyImpl as? PasskeyImplementation ?? PasskeyImplementation()
            passkeyImpl = passImpl
            
            if call.method == "registerPasskey" {
                if let args = call.arguments as? [String: Any], let options = args["options"] as? [String: Any] {
                    passImpl.registerPasskey(options: options, result: result)
                } else {
                    result(FlutterError(code: "InvalidArguments", message: "Invalid options", details: nil))
                }
                return
            } else if call.method == "authenticateWithPasskey" {
                if let args = call.arguments as? [String: Any], let options = args["options"] as? [String: Any] {
                    passImpl.authenticateWithPasskey(options: options, result: result)
                } else {
                    result(FlutterError(code: "InvalidArguments", message: "Invalid options", details: nil))
                }
                return
            }
        }
        
        impl.handle(StorageMethodCall(method: call.method, arguments: call.arguments), result: result)
    }
}
