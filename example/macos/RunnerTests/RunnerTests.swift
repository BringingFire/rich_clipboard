//
//  RunnerTests.swift
//  RunnerTests
//
//  Created by Joshua Matthews on 4/9/22.
//

import FlutterMacOS
import rich_clipboard
import XCTest

class RunnerTests: XCTestCase {
    func testGetData_textOnly() throws {
        let plugin = RichClipboardPlugin()
        let textContent = "hello there"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textContent, forType: .string)
        var resultDict: [String: String]?
        plugin.handle(
            FlutterMethodCall(methodName: "RichClipboard.getData", arguments: nil),
            result: { (result: Any?) in
                resultDict = (result as? [String: String])!
            }
        )

        XCTAssertEqual(
            resultDict,
            [
                "text/plain": textContent,
            ]
        )
    }

    func testGetData_withHtml() throws {
        let plugin = RichClipboardPlugin()
        let textContent = "hello there"
        let htmlContent = "<h1>\(textContent)</h1>"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textContent, forType: .string)
        NSPasteboard.general.setString(htmlContent, forType: .html)
        var resultDict: [String: String?]?
        plugin.handle(
            FlutterMethodCall(methodName: "RichClipboard.getData", arguments: nil),
            result: { (result: Any?) in
                resultDict = (result as? [String: String?])!
            }
        )

        XCTAssertEqual(
            resultDict,
            [
                "text/plain": textContent,
                "text/html": htmlContent,
            ]
        )
    }

    func testGetData_rtfToHtml() throws {
        let plugin = RichClipboardPlugin()
        let textContent = "hello there"
        let rtfContent = #"""
        {\rtf1\ansi\ansicpg1252\cocoartf2638
        \cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 AppleSystemUIFont;}
        {\colortbl;\red255\green255\blue255;}
        {\*\expandedcolortbl;;}
        \deftab560
        \pard\pardeftab560\slleading20\partightenfactor0

        \f0\fs26 \AppleTypeServices\AppleTypeServicesF2293774 \cf0 hello there}
        """#
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textContent, forType: .string)
        NSPasteboard.general.setString(rtfContent, forType: .rtf)
        var resultDict: [String: String]?
        plugin.handle(
            FlutterMethodCall(methodName: "RichClipboard.getData", arguments: nil),
            result: { (result: Any?) in
                resultDict = (result as? [String: String])!
            }
        )

        XCTAssertNotNil(resultDict)
        XCTAssertEqual(resultDict!.count, 2)
        XCTAssertEqual(resultDict!["text/plain"], textContent)
        XCTAssertNotNil(resultDict!["text/html"])
        XCTAssertTrue(resultDict!["text/html"]!.contains("hello there"))
        XCTAssertTrue(resultDict!["text/html"]!.contains("Cocoa HTML Writer"))
    }
}
