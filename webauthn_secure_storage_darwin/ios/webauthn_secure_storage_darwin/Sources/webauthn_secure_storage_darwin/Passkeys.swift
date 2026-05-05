import Foundation
import AuthenticationServices
import Flutter

@available(iOS 16.0, macOS 12.0, *)
class PasskeyImplementation: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var result: FlutterResult?
    
    func registerPasskey(options: [String: Any], result: @escaping FlutterResult) {
        self.result = result
        guard let challengeString = options["challenge"] as? String,
              let challengeData = Data(base64Encoded: challengeString),
              let rpItem = options["rp"] as? [String: Any],
              let rpId = rpItem["id"] as? String,
              let userItem = options["user"] as? [String: Any],
              let userIdString = userItem["id"] as? String,
              let userId = Data(base64Encoded: userIdString),
              let userName = userItem["name"] as? String else {
            result(FlutterError(code: "InvalidOptions", message: "Missing required passkey creation options", details: nil))
            return
        }
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let request = provider.createCredentialRegistrationRequest(challenge: challengeData, name: userName, userID: userId)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func authenticateWithPasskey(options: [String: Any], result: @escaping FlutterResult) {
        self.result = result
        guard let challengeString = options["challenge"] as? String,
              let challengeData = Data(base64Encoded: challengeString),
              let rpId = options["rpId"] as? String else {
            result(FlutterError(code: "InvalidOptions", message: "Missing required passkey request options", details: nil))
            return
        }
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let request = provider.createCredentialAssertionRequest(challenge: challengeData)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.delegate?.window??.rootViewController?.view.window ?? UIWindow()
        #else
        return NSApplication.shared.keyWindow ?? NSWindow()
        #endif
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            let response: [String: Any] = [
                "id": credential.credentialID.base64EncodedString(),
                "rawId": credential.credentialID.base64EncodedString(),
                "type": "public-key",
                "response": [
                    "clientDataJSON": credential.rawClientDataJSON.base64EncodedString(),
                    "attestationObject": credential.rawAttestationObject?.base64EncodedString() ?? ""
                ]
            ]
            result?(response)
        } else if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            let response: [String: Any] = [
                "id": credential.credentialID.base64EncodedString(),
                "rawId": credential.credentialID.base64EncodedString(),
                "type": "public-key",
                "response": [
                    "clientDataJSON": credential.rawClientDataJSON.base64EncodedString(),
                    "authenticatorData": credential.rawAuthenticatorData.base64EncodedString(),
                    "signature": credential.signature.base64EncodedString(),
                    "userHandle": credential.userID?.base64EncodedString() ?? ""
                ]
            ]
            result?(response)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        result?(FlutterError(code: "PasskeyError", message: error.localizedDescription, details: nil))
    }
}
