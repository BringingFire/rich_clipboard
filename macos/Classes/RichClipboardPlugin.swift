import Cocoa
import FlutterMacOS

public class RichClipboardPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "rich_clipboard", binaryMessenger: registrar.messenger)
        let instance = RichClipboardPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "RichClipboard.getData":
            result(getData())
        case "RichClipboard.setData":
            setData(call.arguments)
            result(nil)
        case "getItemCount":
            result(getItemCount())
        case "getAvailableTypes":
            result(getAvailableTypes())
        case "asHtml":
            result(asHtml())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func getData() -> [String: String?] {
        let board = NSPasteboard.general
        let text = board.string(forType: .string)
        let html = board.string(forType: .html) ?? getRtfAsHtml()
        return [
            "text/plain": text,
            "text/html": html,
        ]
    }

    func setData(_ arguments: Any?) {
        guard let data = arguments as? [String: String] else {
            return
        }

        guard let text = data["text/plain"] else {
            return
        }

        let board = NSPasteboard.general
        board.clearContents()

        board.setString(text, forType: .string)

        if let html = data["text/html"] {
            board.setString(html, forType: .html)
        }
    }

    func getRtfAsHtml() -> String? {
        if let boardRtf = NSPasteboard.general.data(forType: .rtf) {
            if let attrStr = NSAttributedString(rtf: boardRtf, documentAttributes: nil) {
                if let htmlData = try? attrStr.data(
                    from: NSRange(location: 0, length: attrStr.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
                {
                    if let htmlStr = String(data: htmlData, encoding: String.Encoding.utf8) {
                        return htmlStr
                    }
                }
            }
        }
        return nil
    }

    func getItemCount() -> Int {
        NSPasteboard.general.pasteboardItems?.count ?? 0
    }

    func asHtml() -> String? {
        let board = NSPasteboard.general
        if let boardHtml = board.string(forType: .html) {
            return boardHtml
        }
        if let boardRtf = board.data(forType: .rtf) {
            if let attrStr = NSAttributedString(rtf: boardRtf, documentAttributes: nil) {
                if let htmlData = try? attrStr.data(
                    from: NSRange(location: 0, length: attrStr.length),
                    documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html])
                {
                    if let htmlStr = String(data: htmlData, encoding: String.Encoding.utf8) {
                        return htmlStr
                    }
                }
            }
        }
        return nil
    }

    func getAvailableTypes() -> [String] {
        if let types = NSPasteboard.general.types {
            return types.map { type in
                type.rawValue
            }
        }
        return ["NOPE"]
    }
}
