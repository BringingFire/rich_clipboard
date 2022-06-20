import Flutter
import UniformTypeIdentifiers

let mimeTextPlain = "text/plain"
let mimeTextHtml = "text/html"
let utTypeTextPlain = "public.text"
let utTypeTextHtml = "public.html"
let utTypeTextRtf = "public.rtf"

public class RichClipboardPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.bringingfire.rich_clipboard", binaryMessenger: registrar.messenger())
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
        let board = UIPasteboard.general
        var result: [String: String] = [:]
        if let text = board.string {
            result[mimeTextPlain] = text
        }
        if let htmlData = board.data(forPasteboardType: utTypeTextHtml) {
            let html = String(data: htmlData, encoding: .utf8)
            result[mimeTextHtml] = html
        } else if let rtfData = board.data(forPasteboardType: utTypeTextRtf) {
            do {
                let rtfAttrString = try NSAttributedString(
                    data: rtfData,
                    documentAttributes: nil)
                let htmlData = try rtfAttrString.data(from: NSRange(location: 0, length: rtfAttrString.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
                result[mimeTextHtml] = String(data: htmlData, encoding: .utf8)
            } catch {}
        }
        return result
    }

    func setData(_ arguments: Any?) {
        let board = UIPasteboard.general
        board.items = [[:]]

        guard let data = arguments as? [String: String] else {
            return
        }

        if let text = data[mimeTextPlain] {
            board.items[0][utTypeTextPlain] = text
//            board.setValue(text, forPasteboardType: utTypeTextPlain)
        }

//        if let html = data[mimeTextHtml] {
//            board.items[0][utTypeTextHtml] = html
        ////            board.setValue(html, forPasteboardType: utTypeTextHtml)
//        }
    }

//
//    func getRtfAsHtml() -> String? {
//        guard let boardRtf = NSPasteboard.general.data(forType: .rtf) else {
//            return nil
//        }
//        guard let attrStr = NSAttributedString(rtf: boardRtf, documentAttributes: nil) else {
//            return nil
//        }
//        guard let htmlData = try? attrStr.data(
//            from: NSRange(location: 0, length: attrStr.length),
//            documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
//        else {
//            return nil
//        }
//        return String(data: htmlData, encoding: String.Encoding.utf8)
//    }
//
    func getAvailableTypes() -> [String] {
        return UIPasteboard.general.types
    }
}
