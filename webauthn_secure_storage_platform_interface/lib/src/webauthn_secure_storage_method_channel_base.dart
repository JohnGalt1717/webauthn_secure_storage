import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'passkey_types.dart';
import 'webauthn_secure_storage_platform.dart';
import 'types.dart';

abstract class MethodChannelBiometricStoragePlatform
    extends BiometricStoragePlatform {
  MethodChannelBiometricStoragePlatform();

  static const MethodChannel channel = MethodChannel('webauthn_secure_storage');
  static final Logger logger = Logger('webauthn_secure_storage');

  Map<String, dynamic> buildPromptInfoArguments(PromptInfo promptInfo);

  @override
  Future<PublicKeyCredentialAttestationJson> registerPasskey(
    PublicKeyCredentialCreationOptionsJson options,
  ) async {
    final Map<String, dynamic>? result = await transformErrors(
      channel.invokeMapMethod<String, dynamic>(
        'registerPasskey',
        <String, dynamic>{'options': options.toJson()},
      ),
    );

    if (result == null) {
      throw AuthException(
        AuthExceptionCode.unknown,
        'registerPasskey returned null.',
      );
    }

    return PublicKeyCredentialAttestationJson.fromJson(result);
  }

  @override
  Future<PublicKeyCredentialAssertionJson> authenticateWithPasskey(
    PublicKeyCredentialRequestOptionsJson options,
  ) async {
    final Map<String, dynamic>? result = await transformErrors(
      channel.invokeMapMethod<String, dynamic>(
        'authenticateWithPasskey',
        <String, dynamic>{'options': options.toJson()},
      ),
    );

    if (result == null) {
      throw AuthException(
        AuthExceptionCode.unknown,
        'authenticateWithPasskey returned null.',
      );
    }

    return PublicKeyCredentialAssertionJson.fromJson(result);
  }

  @override
  Future<bool?> init(
    String name, {
    StorageFileInitOptions? options,
    bool forceInit = false,
  }) => transformErrors(
    channel.invokeMethod<bool>('init', <String, dynamic>{
      'name': name,
      'options': options?.toJson() ?? StorageFileInitOptions().toJson(),
      'forceInit': forceInit,
    }),
  );

  @override
  Future<String?> read(
    String name,
    PromptInfo promptInfo, {
    bool forceBiometricAuthentication = false,
  }) => transformErrors(
    channel.invokeMethod<String>('read', <String, dynamic>{
      'name': name,
      'forceBiometricAuthentication': forceBiometricAuthentication,
      ...buildPromptInfoArguments(promptInfo),
    }),
  );

  @override
  Future<bool> exists(String name, PromptInfo promptInfo) => transformErrors(
    channel.invokeMethod<bool>('exists', <String, dynamic>{
      'name': name,
      ...buildPromptInfoArguments(promptInfo),
    }),
  ).then((value) => value ?? false);

  @override
  Future<bool?> delete(String name, PromptInfo promptInfo) => transformErrors(
    channel.invokeMethod<bool>('delete', <String, dynamic>{
      'name': name,
      ...buildPromptInfoArguments(promptInfo),
    }),
  );

  @override
  Future<void> write(
    String name,
    String content,
    PromptInfo promptInfo, {
    bool forceBiometricAuthentication = false,
  }) => transformErrors(
    channel.invokeMethod<void>('write', <String, dynamic>{
      'name': name,
      'content': content,
      'forceBiometricAuthentication': forceBiometricAuthentication,
      ...buildPromptInfoArguments(promptInfo),
    }),
  );

  @override
  Future<void> dispose(String name, PromptInfo promptInfo) => transformErrors(
    channel.invokeMethod<void>('dispose', <String, dynamic>{
      'name': name,
      ...buildPromptInfoArguments(promptInfo),
    }),
  );

  Future<T> transformErrors<T>(Future<T> future) =>
      future.catchError((Object error, StackTrace stackTrace) {
        if (error is PlatformException) {
          logger.finest(
            'Error during plugin operation (details: ${error.details})',
            error,
            stackTrace,
          );
          if (error.code.startsWith('AuthError:')) {
            return Future<T>.error(
              AuthException(
                authErrorCodeMapping[error.code] ?? AuthExceptionCode.unknown,
                error.message ?? 'Unknown error',
              ),
              stackTrace,
            );
          }
          final message = error.message ?? '';
          if (message.contains('org.freedesktop.DBus.Error.AccessDenied') ||
              message.contains('AppArmor')) {
            logger.fine('Got app armor error.');
            return Future<T>.error(
              AuthException(
                AuthExceptionCode.linuxAppArmorDenied,
                error.message ?? 'Unknown error',
              ),
              stackTrace,
            );
          }
        }
        return Future<T>.error(error, stackTrace);
      });
}
