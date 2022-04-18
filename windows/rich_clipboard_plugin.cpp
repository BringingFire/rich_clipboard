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

  std::optional<std::string> CfToString(UINT cf_format)
  {
    switch (cf_format)
    {
    case CF_TEXT:
      return "CF_TEXT";
    case CF_BITMAP:
      return "CF_BITMAP";
    case CF_METAFILEPICT:
      return "CF_METAFILEPICT";
    case CF_SYLK:
      return "CF_SYLK";
    case CF_DIF:
      return "CF_DIF";
    case CF_TIFF:
      return "CF_TIFF";
    case CF_OEMTEXT:
      return "CF_OEMTEXT";
    case CF_DIB:
      return "CF_DIB";
    case CF_PALETTE:
      return "CF_PALETTE";
    case CF_PENDATA:
      return "CF_PENDATA";
    case CF_RIFF:
      return "CF_RIFF";
    case CF_WAVE:
      return "CF_WAVE";
    case CF_UNICODETEXT:
      return "CF_UNICODETEXT";
    case CF_ENHMETAFILE:
      return "CF_ENHMETAFILE";
    case CF_HDROP:
      return "CF_HDROP";
    case CF_LOCALE:
      return "CF_LOCALE";
    case CF_DIBV5:
      return "CF_DIBV5";
    case CF_MAX:
      return "CF_MAX";
    case CF_OWNERDISPLAY:
      return "CF_OWNERDISPLAY";
    case CF_DSPTEXT:
      return "CF_DSPTEXT";
    case CF_DSPBITMAP:
      return "CF_DSPBITMAP";
    case CF_DSPMETAFILEPICT:
      return "CF_DSPMETAFILEPICT";
    case CF_DSPENHMETAFILE:
      return "CF_DSPENHMETAFILE";
    case CF_PRIVATEFIRST:
      return "CF_PRIVATEFIRST";
    case CF_PRIVATELAST:
      return "CF_PRIVATELAST";
    case CF_GDIOBJFIRST:
      return "CF_GDIOBJFIRST";
    case CF_GDIOBJLAST:
      return "CF_GDIOBJLAST";
    }

    return std::nullopt;
  }

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
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
  if (method_call.method_name().compare("getAvailableTypes") == 0)
  {
    if (!OpenClipboard(NULL))
    {
      result->Error("COULD_NOT_OPEN_CLIPBOARD", "Failed to open clipboard");
      return;
    }

    flutter::EncodableList available_types;
    auto next_type = EnumClipboardFormats(NULL);
    while (next_type != NULL)
    {
      if (auto next_type_string = CfToString(next_type); next_type_string)
      {
        available_types.push_back(flutter::EncodableValue(*next_type_string));
      }
      else
      {
        available_types.push_back(flutter::EncodableValue(std::to_string(next_type)));
      }
      next_type = EnumClipboardFormats(next_type);
    }

    CloseClipboard();
    result->Success(available_types);
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
