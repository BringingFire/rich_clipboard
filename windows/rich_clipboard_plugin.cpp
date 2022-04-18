#include "include/rich_clipboard/rich_clipboard_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

namespace {

class RichClipboardPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  RichClipboardPlugin();

  virtual ~RichClipboardPlugin();

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void RichClipboardPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.bringingfire.rich_clipboard",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<RichClipboardPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

RichClipboardPlugin::RichClipboardPlugin() {}

RichClipboardPlugin::~RichClipboardPlugin() {}

void RichClipboardPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
    return;
  }

  if (method_call.method_name().compare("getAvailableTypes") == 0)
  {
    if (!OpenClipboard(NULL))
    {
      result->Error("COULD_NOT_OPEN_CLIPBOARD", "Failed to open clipboard");
      return;
    }

    flutter::EncodableList availableTypes;
    auto nextType = EnumClipboardFormats(NULL);
    while (nextType != NULL)
    {
      availableTypes.push_back(flutter::EncodableValue(std::to_string(nextType)));
      nextType = EnumClipboardFormats(nextType);
    }

    CloseClipboard();
    result->Success(availableTypes);
    return;
  }

  result->NotImplemented();
}

}  // namespace

void RichClipboardPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  RichClipboardPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
