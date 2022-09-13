#include "include/rich_clipboard_linux/rich_clipboard_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <memory>
#include <string>
#include <cstring>

using namespace std;

const char kChannelName[] = "com.bringingfire.rich_clipboard";
const char kGetData[] = "getData";
const char kSetData[] = "setData";
const char kGetAvailableTypes[] = "getAvailableTypes";
const char kMimeTextPlain[] = "text/plain";
const char kMimeTextHtml[] = "text/html";

const GdkAtom kGdkAtomTextPlain = gdk_atom_intern_static_string(kMimeTextPlain);
const GdkAtom kGdkAtomTextHtml = gdk_atom_intern_static_string(kMimeTextHtml);

const guint kUserInfoTextPlain = 1;
const guint kUserInfoTextHtml = 2;

class RichClipboardData
{
private:
  unique_ptr<string> textPlain;
  unique_ptr<string> textHtml;

public:
  string *getTextPlain()
  {
    return textPlain.get();
  }
  void setTextPlain(const gchar *text)
  {
    textPlain.reset(new string(text));
  }
  string *getTextHtml()
  {
    return textHtml.get();
  }
  void setTextHtml(const gchar *text)
  {
    textHtml.reset(new string(text));
  }
  bool isEmpty()
  {
    return textPlain == nullptr && textHtml == nullptr;
  }
  bool isNotEmpty()
  {
    return !isEmpty();
  }
};

struct _FlRichClipboardPlugin
{
  GObject parent_instance;

  FlPluginRegistrar *registrar;

  // Connection to Flutter engine.
  FlMethodChannel *channel;
};

G_DEFINE_TYPE(FlRichClipboardPlugin, fl_rich_clipboard_plugin, g_object_get_type())

static void gtk_clipboard_request_targets_callback(
    GtkClipboard *clipboard,
    GdkAtom *atoms,
    gint n_atoms,
    gpointer user_data)
{
  g_autoptr(FlMethodCall) method_call = static_cast<FlMethodCall *>(user_data);

  g_autoptr(FlValue) result = fl_value_new_list();
  for (gint i = 0; i < n_atoms; i++)
  {
    auto target = gdk_atom_name(atoms[i]);
    fl_value_append_take(result, fl_value_new_string(target));
    g_free(target);
  }
  fl_method_call_respond_success(method_call, result, nullptr);
}

static void gtk_clipboard_get_target_text_callback(
    GtkClipboard *clipboard,
    GtkSelectionData *selectionData,
    guint info,
    gpointer user_data_or_owner)
{
  auto *clipboardData = reinterpret_cast<RichClipboardData *>(user_data_or_owner);
  if (info == kUserInfoTextPlain && clipboardData->getTextPlain() != nullptr)
  {
    auto *textPlainCString = clipboardData->getTextPlain()->c_str();
    gtk_selection_data_set_text(selectionData, textPlainCString, strlen(textPlainCString));
  }
  else if (info == kUserInfoTextHtml && clipboardData->getTextHtml() != nullptr)
  {
    auto *textHtmlCString = clipboardData->getTextHtml()->c_str();
    gtk_selection_data_set(selectionData, kGdkAtomTextHtml, 8, (guchar *)textHtmlCString, strlen(textHtmlCString));
  }
}

static void gtk_clipboard_clear_text_callback(GtkClipboard *clipboard, gpointer user_data_or_owner)
{
  auto *clipboardData = reinterpret_cast<RichClipboardData *>(user_data_or_owner);
  delete clipboardData;
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data)
{
  const gchar *method = fl_method_call_get_name(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kGetAvailableTypes) == 0)
  {
    auto *clipboard = gtk_clipboard_get_default(gdk_display_get_default());
    gtk_clipboard_request_targets(
        clipboard,
        gtk_clipboard_request_targets_callback,
        g_object_ref(method_call));
  }
  else if (strcmp(method, kGetData) == 0)
  {
    auto *clipboard = gtk_clipboard_get_default(gdk_display_get_default());
    g_autoptr(FlValue) result = fl_value_new_map();

    auto *text = gtk_clipboard_wait_for_text(clipboard);
    if (text != nullptr)
    {
      fl_value_set_string_take(result, kMimeTextPlain, fl_value_new_string(text));
      g_free(text);
    }

    auto *htmlData = gtk_clipboard_wait_for_contents(clipboard, kGdkAtomTextHtml);
    if (htmlData != nullptr)
    {
      // Testing shows that GTK will just return plain if no HTML data is available, so make sure we actually
      // have HTML before adding it to the result map.
      auto htmlType = gtk_selection_data_get_data_type(htmlData);
      auto *htmlTypeName = gdk_atom_name(htmlType);
      if (strcmp(htmlTypeName, kMimeTextHtml) == 0)
      {
        gint htmlLen;
        auto *html = gtk_selection_data_get_data_with_length(htmlData, &htmlLen);
        if (html != nullptr)
        {
          fl_value_set_string_take(result, kMimeTextHtml, fl_value_new_string_sized((gchar *)html, htmlLen));
        }
      }
      g_free(htmlTypeName);
      gtk_selection_data_free(htmlData);
    }

    fl_method_call_respond_success(method_call, result, nullptr);
  }
  else if (strcmp(method, kSetData) == 0)
  {
    auto *clipboard = gtk_clipboard_get_default(gdk_display_get_default());
    gtk_clipboard_clear(clipboard);

    auto *args = fl_method_call_get_args(method_call);

    auto *clipboardData = new RichClipboardData();
    auto *textPlainValue = fl_value_lookup_string(args, kMimeTextPlain);
    if (textPlainValue != nullptr)
    {
      auto *textPlainCString = fl_value_get_string(textPlainValue);
      if (textPlainCString != nullptr)
      {
        clipboardData->setTextPlain(textPlainCString);
      }
    }
    auto *textHtmlValue = fl_value_lookup_string(args, kMimeTextHtml);
    if (textHtmlValue != nullptr)
    {
      auto *textHtmlCString = fl_value_get_string(textHtmlValue);
      if (textHtmlCString != nullptr)
      {
        clipboardData->setTextHtml(textHtmlCString);
      }
    }

    if (clipboardData->isNotEmpty())
    {
      auto *targetList = gtk_target_list_new(nullptr, 0);
      gtk_target_list_add_text_targets(targetList, kUserInfoTextPlain);
      gtk_target_list_add(targetList, kGdkAtomTextHtml, 0, kUserInfoTextHtml);

      gint numTargets = 1;
      auto *targetTable = gtk_target_table_new_from_list(targetList, &numTargets);
      gtk_clipboard_set_with_data(
          clipboard,
          targetTable,
          numTargets,
          gtk_clipboard_get_target_text_callback,
          gtk_clipboard_clear_text_callback,
          clipboardData);
      gtk_clipboard_set_can_store(clipboard, targetTable, numTargets);
      gtk_clipboard_store(clipboard);

      gtk_target_list_unref(targetList);
      gtk_target_table_free(targetTable, numTargets);
    }

    fl_method_call_respond_success(method_call, nullptr, nullptr);
  }
  else
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    g_autoptr(GError) error = nullptr;
    if (!fl_method_call_respond(method_call, response, &error))
      g_warning("Failed to send method call response: %s", error->message);
  }
}

static void fl_rich_clipboard_plugin_dispose(GObject *object)
{
  G_OBJECT_CLASS(fl_rich_clipboard_plugin_parent_class)->dispose(object);
}

static void fl_rich_clipboard_plugin_class_init(FlRichClipboardPluginClass *klass)
{
  G_OBJECT_CLASS(klass)->dispose = fl_rich_clipboard_plugin_dispose;
}

FlRichClipboardPlugin *fl_rich_clipboard_plugin_new(FlPluginRegistrar *registrar)
{
  FlRichClipboardPlugin *self = FL_MY_PLUGIN_PLUGIN(
      g_object_new(fl_rich_clipboard_plugin_get_type(), nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            g_object_ref(self), g_object_unref);

  return self;
}

static void fl_rich_clipboard_plugin_init(FlRichClipboardPlugin *self) {}

void rich_clipboard_plugin_register_with_registrar(FlPluginRegistrar *registrar)
{
  FlRichClipboardPlugin *plugin = fl_rich_clipboard_plugin_new(registrar);
  g_object_unref(plugin);
}
