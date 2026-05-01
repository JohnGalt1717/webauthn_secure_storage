// Shared file between iOS and Mac OS
// make sure they stay in sync.

import Foundation
import LocalAuthentication

private let currentKeychainService = "flutter_webauthn_secure_storage"
private let legacyKeychainService = "flutter_biometric_storage"

typealias StorageCallback = (Any?) -> Void
typealias StorageError = (String, String?, Any?) -> Any

struct StorageMethodCall {
       let method: String
       let arguments: Any?
}

class InitOptions {
       init(params: [String: Any]) {
		 darwinTouchIDAuthenticationAllowableReuseDuration = params["darwinTouchIDAuthenticationAllowableReuseDurationSeconds"] as? Int
		 darwinTouchIDAuthenticationForceReuseContextDuration = params["darwinTouchIDAuthenticationForceReuseContextDurationSeconds"] as? Int
		 authenticationRequired = params["authenticationRequired"] as? Bool
		 darwinBiometricOnly = params["darwinBiometricOnly"] as? Bool
       }
       let darwinTouchIDAuthenticationAllowableReuseDuration: Int?
       let darwinTouchIDAuthenticationForceReuseContextDuration: Int?
       let authenticationRequired: Bool!
       let darwinBiometricOnly: Bool!
}

class IOSPromptInfo {
       init(params: [String: Any]) {
		 saveTitle = params["saveTitle"] as? String
		 accessTitle = params["accessTitle"] as? String
       }
       let saveTitle: String!
       let accessTitle: String!
}

class BiometricStorageImpl {
    
	init(storageError: @escaping StorageError, storageMethodNotImplemented: Any) {
		self.storageError = storageError
		self.storageMethodNotImplemented = storageMethodNotImplemented
	}

	private var stores: [String: BiometricStorageFile] = [:]
	private let storageError: StorageError
	private let storageMethodNotImplemented: Any
    
	private func storageError(code: String, message: String?, details: Any?) -> Any {
		return storageError(code, message, details)
	}
    
	public func handle(_ call: StorageMethodCall, result: @escaping StorageCallback) {
        
		func requiredArg<T>(_ name: String, _ cb: (T) -> Void) {
			guard let args = call.arguments as? Dictionary<String, Any> else {
				result(storageError(code: "InvalidArguments", message: "Invalid arguments \(String(describing: call.arguments))", details: nil))
				return
			}
			guard let value = args[name] else {
				result(storageError(code: "InvalidArguments", message: "Missing argument \(name)", details: nil))
				return
			}
			guard let valueTyped = value as? T else {
				result(storageError(code: "InvalidArguments", message: "Invalid argument for \(name): expected \(T.self) got \(value)", details: nil))
				return
			}
			cb(valueTyped)
			return
		}
		func requireStorage(_ name: String, _ cb: (BiometricStorageFile) -> Void) {
			guard let file = stores[name] else {
				result(storageError(code: "InvalidArguments", message: "Storage was not initialized \(name)", details: nil))
				return
			}
			cb(file)
		}
        
		if ("canAuthenticate" == call.method) {
			requiredArg("options") { options in
				let initOptions = InitOptions(params: options)
				canAuthenticate(options: initOptions, result: result)
			}
		} else if ("init" == call.method) {
			requiredArg("name") { name in
				requiredArg("options") { options in
					stores[name] = BiometricStorageFile(name: name, initOptions: InitOptions(params: options), storageError: storageError)
				}
			}
			result(true)
		} else if ("dispose" == call.method) {
			requiredArg("name") { name in
				guard let file = stores.removeValue(forKey: name) else {
					result(storageError(code: "NoSuchStorage", message: "Tried to dispose non existing storage.", details: nil))
					return
				}
				file.dispose()
				result(true)
			}
		} else if ("read" == call.method) {
			requiredArg("name") { name in
				requiredArg("forceBiometricAuthentication") { forceBiometricAuthentication in
					requiredArg("iosPromptInfo") { promptInfo in
						requireStorage(name) { file in
							file.read(result, IOSPromptInfo(params: promptInfo), forceBiometricAuthentication)
						}
					}
				}
			}
		} else if ("exists" == call.method) {
			requiredArg("name") { name in
				requireStorage(name) { file in
					file.exists(result)
				}
			}
		} else if ("write" == call.method) {
			requiredArg("name") { name in
				requiredArg("content") {
					content in requiredArg("forceBiometricAuthentication") { forceBiometricAuthentication in
						requiredArg("iosPromptInfo") { promptInfo in
							requireStorage(name) { file in
								file.write(content, result, IOSPromptInfo(params: promptInfo), forceBiometricAuthentication)
							}
						}
					}
				}
			}
		} else if ("delete" == call.method) {
			requiredArg("name") { name in
				requiredArg("iosPromptInfo") { promptInfo in
					requireStorage(name) { file in
						file.delete(result, IOSPromptInfo(params: promptInfo))
					}
				}
			}
		} else {
			result(storageMethodNotImplemented)
		}
	}

	private func canAuthenticate(options: InitOptions, result: @escaping StorageCallback) {
		var error: NSError?
		let context = LAContext()
		let policy: LAPolicy = options.darwinBiometricOnly ? .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication
		if context.canEvaluatePolicy(policy, error: &error) {
			result("Success")
			return
		}
		guard let err = error else {
			result("ErrorUnknown")
			return
		}
		let laError = LAError(_nsError: err)
		NSLog("LAError: \(laError)");
		switch laError.code {
		case .touchIDNotAvailable:
			result("ErrorHwUnavailable")
			break;
		case .passcodeNotSet:
			result("ErrorPasscodeNotSet")
			break;
		case .touchIDNotEnrolled:
			result("ErrorNoBiometricEnrolled")
			break;
		case .invalidContext: fallthrough
		default:
			result("ErrorUnknown")
			break;
		}
	}
}

typealias StoredContext = (context: LAContext, expireAt: Date)

class BiometricStorageFile {
	private let name: String
	private let initOptions: InitOptions
	private var _context: StoredContext?
	private var context: LAContext {
		get {
			if let context = _context {
				if context.expireAt.timeIntervalSinceNow < 0 {
					_context = nil
				} else {
					return context.context
				}
			}
            
			let context = LAContext()
			if (initOptions.authenticationRequired) {
				if let duration = initOptions.darwinTouchIDAuthenticationAllowableReuseDuration {
					context.touchIDAuthenticationAllowableReuseDuration = Double(duration)
				}
                
				if let duration = initOptions.darwinTouchIDAuthenticationForceReuseContextDuration {
					_context = (context: context, expireAt: Date(timeIntervalSinceNow: Double(duration)))
				}
			}
			return context
		}
	}
	private let storageError: StorageError
    
	init(name: String, initOptions: InitOptions, storageError: @escaping StorageError) {
		self.name = name
		self.initOptions = initOptions
		self.storageError = storageError
	}

	func dispose() {
		_context = nil
	}
    
	private func baseQuery(_ result: @escaping StorageCallback, service: String = currentKeychainService) -> [String: Any]? {
		var query = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: name,
		] as [String : Any]
		if initOptions.authenticationRequired {
			guard let access = accessControl(result) else {
				return nil
			}
			if #available(iOS 13.0, macOS 10.15, *) {
				query[kSecUseDataProtectionKeychain as String] = true
			}
			query[kSecAttrAccessControl as String] = access
		}
		return query
	}
    
	private func accessControl(_ result: @escaping StorageCallback) -> SecAccessControl? {
		let accessControlFlags: SecAccessControlCreateFlags
		
		if initOptions.darwinBiometricOnly {
			if #available(iOS 11.3, *) {
				accessControlFlags =  .biometryCurrentSet
			} else {
				accessControlFlags = .touchIDCurrentSet
			}
		} else {
			accessControlFlags = .userPresence
		}
		
		var error: Unmanaged<CFError>?
		guard let access = SecAccessControlCreateWithFlags(
			nil,
			kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
			accessControlFlags,
			&error) else {
			result(storageError("writing data", "error writing data", "\(String(describing: error))"));
			return nil
		}
		
		return access
	}

	private func readQuery(_ query: [String: Any], _ result: @escaping StorageCallback, _ promptInfo: IOSPromptInfo, _ forceBiometricAuthentication: Bool) -> String?? {
		var query = query
		if(forceBiometricAuthentication){
			_context = nil
		}
		query[kSecMatchLimit as String] = kSecMatchLimitOne
		query[kSecUseOperationPrompt as String] = promptInfo.accessTitle
		query[kSecReturnAttributes as String] = true
		query[kSecReturnData as String] = true
		query[kSecUseAuthenticationContext as String] = context

		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)
		guard status != errSecItemNotFound else {
			return .some(nil)
		}
		guard status == errSecSuccess else {
			handleOSStatusError(status, result, "Error retrieving item. \(status)")
			return nil
		}
		guard let existingItem = item as? [String : Any],
			  let data = existingItem[kSecValueData as String] as? Data,
			  let dataString = String(data: data, encoding: String.Encoding.utf8)
		else {
			result(storageError("RetrieveError", "Unexpected data.", nil))
			return nil
		}
		return .some(dataString)
	}

	private func existsQuery(_ query: [String: Any], _ result: @escaping StorageCallback) -> Bool? {
		var query = query
		query[kSecMatchLimit as String] = kSecMatchLimitOne
		query[kSecReturnAttributes as String] = false
		if #available(iOS 9.0, macOS 10.11, *) {
			query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
		}

		let status = SecItemCopyMatching(query as CFDictionary, nil)
		switch status {
		case errSecSuccess, errSecInteractionNotAllowed:
			return true
		case errSecItemNotFound:
			return false
		default:
			handleOSStatusError(status, result, "checking for item")
			return nil
		}
	}

	private func deleteQuery(_ query: [String: Any], _ result: @escaping StorageCallback) -> Bool? {
		let status = SecItemDelete(query as CFDictionary)
		if status == errSecSuccess {
			return true
		}
		if status == errSecItemNotFound {
			return false
		}
		handleOSStatusError(status, result, "writing data")
		return nil
	}
    
	func read(_ result: @escaping StorageCallback, _ promptInfo: IOSPromptInfo, _ forceBiometricAuthentication: Bool) {
		guard let currentQuery = baseQuery(result) else {
			return;
		}
		if let currentResult = readQuery(currentQuery, result, promptInfo, forceBiometricAuthentication) {
			if let value = currentResult {
				result(value)
				return
			}
		} else {
			return
		}
		guard let legacyQuery = baseQuery(result, service: legacyKeychainService) else {
			return
		}
		if let legacyResult = readQuery(legacyQuery, result, promptInfo, forceBiometricAuthentication) {
			result(legacyResult)
		}
	}
    
	func delete(_ result: @escaping StorageCallback, _ promptInfo: IOSPromptInfo) {
		guard let currentQuery = baseQuery(result) else {
			return;
		}
		guard let deletedCurrent = deleteQuery(currentQuery, result) else {
			return
		}
		if deletedCurrent {
			result(true)
			return
		}
		guard let legacyQuery = baseQuery(result, service: legacyKeychainService) else {
			return
		}
		guard let deletedLegacy = deleteQuery(legacyQuery, result) else {
			return
		}
		if deletedLegacy || !deletedCurrent {
			result(true)
			return
		}
	}

	func exists(_ result: @escaping StorageCallback) {
		guard let currentQuery = baseQuery(result) else {
			return
		}
		if let currentExists = existsQuery(currentQuery, result) {
			if currentExists {
				result(true)
				return
			}
		} else {
			return
		}
		guard let legacyQuery = baseQuery(result, service: legacyKeychainService) else {
			return
		}
		if let legacyExists = existsQuery(legacyQuery, result) {
			result(legacyExists)
		}
	}
    
	func write(_ content: String, _ result: @escaping StorageCallback, _ promptInfo: IOSPromptInfo, _ forceBiometricAuthentication: Bool) {
		if(forceBiometricAuthentication){
			_context = nil
		}
		
		guard var query = baseQuery(result) else {
			return;
		}
		
		if (initOptions.authenticationRequired) {
			query.merge([
				kSecUseAuthenticationContext as String: context,
			]) { (_, new) in new }
			if let operationPrompt = promptInfo.saveTitle {
				query[kSecUseOperationPrompt as String] = operationPrompt
			}
		}
		query.merge([
			kSecValueData as String: content.data(using: String.Encoding.utf8) as Any,
		]) { (_, new) in new }
		var status = SecItemAdd(query as CFDictionary, nil)
		if (status == errSecDuplicateItem) {
			let update = [kSecValueData as String: query[kSecValueData as String]]
			query.removeValue(forKey: kSecValueData as String)
			status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
		}
		guard status == errSecSuccess else {
			handleOSStatusError(status, result, "writing data")
			return
		}
		result(nil)
	}
    
	private func handleOSStatusError(_ status: OSStatus, _ result: @escaping StorageCallback, _ message: String) {
		var errorMessage: String? = nil
		if #available(iOS 11.3, OSX 10.12, *) {
			errorMessage = SecCopyErrorMessageString(status, nil) as String?
		}
		let code: String
		switch status {
		case errSecUserCanceled:
			code = "AuthError:UserCanceled"
		case errSecAuthFailed:
			code = "AuthError:BiometricsChanged"
		default:
			code = "SecurityError"
		}
        
		result(storageError(code, "Error while \(message): \(status): \(errorMessage ?? "Unknown")", nil))
	}
}