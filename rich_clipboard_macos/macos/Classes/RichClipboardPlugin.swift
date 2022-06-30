import Cocoa
import FlutterMacOS

let mimeTextPlain = "text/plain"
let mimeTextHtml = "text/html"

public class RichClipboardPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.bringingfire.rich_clipboard", binaryMessenger: registrar.messenger)
        let instance = RichClipboardPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getData":
            result(getData())
        case "setData":
            setData(call.arguments)
            result(nil)
        case "getAvailableTypes":
            result(getAvailableTypes())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func getData() -> [String: String] {
        let board = NSPasteboard.general
        var result: [String: String] = [:]
        if let text = board.string(forType: .string) {
            result[mimeTextPlain] = text
        }
        if let html = board.string(forType: .html) ?? getRtfAsHtml() {
            result[mimeTextHtml] = html
        }
        return result
    }

    func setData(_ arguments: Any?) {
        guard let data = (arguments as? [String: String?])?.compactMapValues({ $0 }) else {
            return
        }

        let board = NSPasteboard.general
        board.clearContents()

        if let text = data[mimeTextPlain] {
            board.setString(text, forType: .string)
        }

        if let html = data[mimeTextHtml] {
            board.setString(html, forType: .html)
        }
    }

    func getRtfAsHtml() -> String? {
        guard let boardRtf = NSPasteboard.general.data(forType: .rtf) else {
            return nil
        }
        guard let attrStr = NSAttributedString(rtf: boardRtf, documentAttributes: nil) else {
            return nil
        }
        guard let htmlData = try? attrStr.data(
            from: NSRange(location: 0, length: attrStr.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
        else {
            return nil
        }
        return String(data: htmlData, encoding: String.Encoding.utf8)
    }

    func getAvailableTypes() -> [String] {
        guard let types = NSPasteboard.general.types else {
            return []
        }
        return types.map { type in
            type.rawValue
        }
    }
}
