import Foundation
import AuthenticationServices

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension String {
    func base64UrlDecodedData() -> Data? {
        var base64 = self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let paddingLength = (4 - base64.count % 4) % 4
        base64.append(String(repeating: "=", count: paddingLength))
        return Data(base64Encoded: base64)
    }
}

@available(iOS 16.0, macOS 12.0, *)
class PasskeyImplementation: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var result: ((Any?) -> Void)?
    
    func registerPasskey(options: [String: Any], result: @escaping (Any?) -> Void) {
        self.result = result
        guard let challengeString = options["challenge"] as? String,
              let challengeData = challengeString.base64UrlDecodedData(),
              let rpItem = options["rp"] as? [String: Any],
              let userItem = options["user"] as? [String: Any],
              let userIdString = userItem["id"] as? String,
              let userId = userIdString.base64UrlDecodedData(),
              let userName = userItem["name"] as? String else {
            result(NSError(domain: "webauthn_secure_storage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid options"]))
            return
        }
        
        let rpId = (rpItem["id"] as? String) ?? "localhost"
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let request = provider.createCredentialRegistrationRequest(challenge: challengeData, name: userName, userID: userId)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func authenticateWithPasskey(options: [String: Any], result: @escaping (Any?) -> Void) {
        self.result = result
        guard let challengeString = options["challenge"] as? String,
              let challengeData = challengeString.base64UrlDecodedData() else {
            result(NSError(domain: "webauthn_secure_storage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid options"]))
            return
        }
        
        let rpId = options["rpId"] as? String ?? "localhost"
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let request = provider.createCredentialAssertionRequest(challenge: challengeData)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
#if os(iOS)
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first ?? ASPresentationAnchor()
#elseif os(macOS)
        return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
#else
        return ASPresentationAnchor()
#endif
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            let res: [String: Any] = [
                "id": credential.credentialID.base64EncodedString(),
                "rawId": credential.credentialID.base64EncodedString(),
                "type": "public-key",
                "response": [
                    "clientDataJSON": credential.rawClientDataJSON.base64EncodedString(),
                    "attestationObject": credential.rawAttestationObject?.base64EncodedString() ?? ""
                ]
            ]
            result?(res)
        } else if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            let res: [String: Any] = [
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
            result?(res)
        } else {
            result?(NSError(domain: "webauthn_secure_storage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown credential"]))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        result?(error)
    }
}
