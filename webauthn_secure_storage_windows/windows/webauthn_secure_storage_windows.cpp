#include "include/webauthn_secure_storage_windows/webauthn_secure_storage_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "webauthn_secure_storage_windows_plugin.h"

void WebauthnSecureStorageWindowsPluginRegisterWithRegistrar(
        FlutterDesktopPluginRegistrarRef registrar) {
    webauthn_secure_storage_windows::WebauthnSecureStorageWindowsPlugin::RegisterWithRegistrar(
            flutter::PluginRegistrarManager::GetInstance()
                    ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void WebauthnSecureStorageWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  webauthn_secure_storage_windows::WebauthnSecureStorageWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}