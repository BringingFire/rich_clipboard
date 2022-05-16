package com.bringingfire.rich_clipboard

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class RichClipboardPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.bringingfire.rich_clipboard")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getAvailableTypes" -> {
                getAvailableTypes(result)
            }
            "getData" -> {
                getData(result)
            }
            "setData" -> {
                setData(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    private fun getAvailableTypes(@NonNull result: Result) {
        val clipboard = context!!.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        if (clip == null || clip.itemCount < 1) {
            result.success(emptyList<String>())
            return
        }
        val mimeTypes = clip.description.filterMimeTypes("*/*").toList()
        result.success(mimeTypes)
    }

    private fun getData(@NonNull result: Result) {
        val clipboard = context!!.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        if (clip == null || clip.itemCount < 1) {
            result.success(emptyMap<String, String>())
            return
        }

        val output = mutableMapOf<String, String>()
        for (i in 0 until clip.itemCount) {
            val item = clip.getItemAt(i)
            if (item.text != null) {
                output["text/plain"] = item.text.toString()
            }
            if (item.htmlText != null) {
                output["text/html"] = item.htmlText.toString()
            }
        }

        result.success(output)
    }

    private fun setData(@NonNull call: MethodCall, @NonNull result: Result) {
        val args = call.arguments<Map<String, String>>()!!
        val clipboard = context!!.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            clipboard.clearPrimaryClip()
        }

        if (args.contains("text/plain") && args.contains("text/html")) {
            val clip = ClipData.newHtmlText("text/plain", args["text/plain"], args["text/html"])
            clipboard.setPrimaryClip(clip)
        } else if (args.contains("text/plain")) {
            val clip = ClipData.newPlainText("text/plain", args["text/plain"])
            clipboard.setPrimaryClip(clip)
        }

        result.success(null)
    }
}