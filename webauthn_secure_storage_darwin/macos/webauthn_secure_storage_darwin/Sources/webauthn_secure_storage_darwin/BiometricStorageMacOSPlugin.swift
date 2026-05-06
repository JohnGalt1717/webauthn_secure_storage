import Cocoa
import FlutterMacOS

public class BiometricStorageMacOSPlugin: NSObject, FlutterPlugin {

    private var passkeyImpl: Any? // Store reference to prevent deallocation

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "webauthn_secure_storage", binaryMessenger: registrar.messenger)
        let instance = BiometricStorageMacOSPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(macOS 12.0, *) {
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

        let biometricImpl = BiometricStorageImpl(storageError: { (code, message, details) -> Any in
            FlutterError(code: code, message: message, details: details)
        }, storageMethodNotImplemented: FlutterMethodNotImplemented)
        biometricImpl.handle(StorageMethodCall(method: call.method, arguments: call.arguments), result: result)
    }
}