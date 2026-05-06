#include "webauthn_secure_storage_windows_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <string>

namespace webauthn_secure_storage_windows {

namespace {

constexpr auto kChannelName = "webauthn_secure_storage";
constexpr auto kMethodGetUserConsentAvailability =
    "windowsGetUserConsentAvailability";
constexpr auto kMethodRequestUserConsentVerification =
    "windowsRequestUserConsentVerification";

std::string ToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }

  const int size_needed = ::WideCharToMultiByte(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0,
      nullptr, nullptr);
  if (size_needed <= 0) {
    return std::string();
  }

  std::string result(size_needed, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, value.c_str(),
                        static_cast<int>(value.size()), result.data(),
                        size_needed, nullptr, nullptr);
  return result;
}

void EnsureApartmentInitialized() {
  try {
    winrt::init_apartment();
  } catch (const winrt::hresult_error& error) {
    if (error.code() != winrt::hresult{RPC_E_CHANGED_MODE}) {
      throw;
    }
  }
}

template <typename TAsyncOperation>
winrt::Windows::Foundation::AsyncStatus WaitForCompletion(
    const TAsyncOperation& operation) {
  const auto async_info = operation.template as<winrt::Windows::Foundation::IAsyncInfo>();

  while (async_info.Status() == winrt::Windows::Foundation::AsyncStatus::Started) {
    ::SleepEx(16, TRUE);
  }

  if (async_info.Status() == winrt::Windows::Foundation::AsyncStatus::Error) {
    throw winrt::hresult_error(async_info.ErrorCode());
  }

  return async_info.Status();
}

std::string AvailabilityToString(
    winrt::Windows::Security::Credentials::UI::UserConsentVerifierAvailability
        availability) {
  using winrt::Windows::Security::Credentials::UI::UserConsentVerifierAvailability;

  switch (availability) {
    case UserConsentVerifierAvailability::Available:
      return "Available";
    case UserConsentVerifierAvailability::DeviceNotPresent:
      return "DeviceNotPresent";
    case UserConsentVerifierAvailability::NotConfiguredForUser:
      return "NotConfiguredForUser";
    case UserConsentVerifierAvailability::DisabledByPolicy:
      return "DisabledByPolicy";
    case UserConsentVerifierAvailability::DeviceBusy:
      return "DeviceBusy";
  }

  return "Unknown";
}

std::string VerificationResultToString(
    winrt::Windows::Security::Credentials::UI::UserConsentVerificationResult
        verification_result) {
  using winrt::Windows::Security::Credentials::UI::UserConsentVerificationResult;

  switch (verification_result) {
    case UserConsentVerificationResult::Verified:
      return "Verified";
    case UserConsentVerificationResult::DeviceNotPresent:
      return "DeviceNotPresent";
    case UserConsentVerificationResult::NotConfiguredForUser:
      return "NotConfiguredForUser";
    case UserConsentVerificationResult::DisabledByPolicy:
      return "DisabledByPolicy";
    case UserConsentVerificationResult::DeviceBusy:
      return "DeviceBusy";
    case UserConsentVerificationResult::RetriesExhausted:
      return "RetriesExhausted";
    case UserConsentVerificationResult::Canceled:
      return "Canceled";
  }

  return "Unknown";
}

}  // namespace

void WebauthnSecureStorageWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin =
      std::make_unique<WebauthnSecureStorageWindowsPlugin>(registrar);

  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WebauthnSecureStorageWindowsPlugin::WebauthnSecureStorageWindowsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

WebauthnSecureStorageWindowsPlugin::~WebauthnSecureStorageWindowsPlugin() = default;

HWND WebauthnSecureStorageWindowsPlugin::GetWindow() const {
  if (registrar_ != nullptr && registrar_->GetView() != nullptr) {
    const auto root =
        ::GetAncestor(registrar_->GetView()->GetNativeWindow(), GA_ROOT);
    if (root != nullptr) {
      return root;
    }
  }

  if (const auto foreground = ::GetForegroundWindow(); foreground != nullptr) {
    return foreground;
  }

  return ::GetActiveWindow();
}

void WebauthnSecureStorageWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    EnsureApartmentInitialized();

    if (method_call.method_name() == kMethodGetUserConsentAvailability) {
      const auto operation =
          winrt::Windows::Security::Credentials::UI::UserConsentVerifier::CheckAvailabilityAsync();
      const auto status = WaitForCompletion(operation);
      if (status == winrt::Windows::Foundation::AsyncStatus::Canceled) {
        result->Success(flutter::EncodableValue("Unknown"));
        return;
      }

      result->Success(flutter::EncodableValue(
          AvailabilityToString(operation.GetResults())));
      return;
    }

    if (method_call.method_name() == kMethodRequestUserConsentVerification) {
      const auto* arguments =
          std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments == nullptr) {
        result->Error("InvalidArguments",
                      "Expected a map containing a verification reason.");
        return;
      }

      const auto reason_iterator =
          arguments->find(flutter::EncodableValue("reason"));
      const auto reason =
          reason_iterator != arguments->end() &&
                  std::holds_alternative<std::string>(reason_iterator->second)
              ? std::get<std::string>(reason_iterator->second)
              : std::string("Use Windows Hello to continue.");

      const auto window = GetWindow();
      if (window == nullptr) {
        result->Error("WindowsHelloError",
                      "Unable to determine a parent window for Windows Hello.");
        return;
      }

      const auto interop = winrt::get_activation_factory<
          winrt::Windows::Security::Credentials::UI::UserConsentVerifier,
          IUserConsentVerifierInterop>();
      const auto reason_hstring = winrt::to_hstring(reason);
      const auto operation = winrt::capture<
          winrt::Windows::Foundation::IAsyncOperation<
              winrt::Windows::Security::Credentials::UI::
                  UserConsentVerificationResult>>(
          interop, &IUserConsentVerifierInterop::RequestVerificationForWindowAsync,
          window, reinterpret_cast<HSTRING>(winrt::get_abi(reason_hstring)));
      const auto status = WaitForCompletion(operation);
      if (status == winrt::Windows::Foundation::AsyncStatus::Canceled) {
        result->Success(flutter::EncodableValue("Canceled"));
        return;
      }

      result->Success(flutter::EncodableValue(
          VerificationResultToString(operation.GetResults())));
      return;
    }

    result->NotImplemented();
  } catch (const winrt::hresult_error& error) {
    result->Error("WindowsHelloError", ToUtf8(error.message().c_str()),
                  flutter::EncodableValue(error.code().value));
  } catch (const std::exception& error) {
    result->Error("WindowsHelloError", error.what());
  }
}

}  // namespace webauthn_secure_storage_windows