// INITests.swift
// Comprehensive tests for the INI library

import XCTest

@testable import INI

final class INITests: XCTestCase {

    // MARK: - Basic Structure Tests

    func testEmptyINI() {
        let ini = INI()
        XCTAssertTrue(ini.isEmpty)
        XCTAssertEqual(ini.sectionNames, [])
    }

    func testGlobalSection() {
        var ini = INI()
        ini.global["key1"] = "value1"
        ini.global["key2"] = "value2"

        XCTAssertEqual(ini.global["key1"], "value1")
        XCTAssertEqual(ini.global["key2"], "value2")
        XCTAssertFalse(ini.isEmpty)
    }

    func testNamedSection() {
        var ini = INI()
        ini["section1", "key1"] = "value1"
        ini["section1", "key2"] = "value2"

        XCTAssertEqual(ini["section1", "key1"], "value1")
        XCTAssertEqual(ini["section1", "key2"], "value2")
        XCTAssertEqual(ini.sectionNames, ["section1"])
    }

    func testMultipleSections() {
        var ini = INI()
        ini["section1", "key1"] = "value1"
        ini["section2", "key2"] = "value2"
        ini["section3", "key3"] = "value3"

        XCTAssertEqual(ini.sectionNames.sorted(), ["section1", "section2", "section3"])
        XCTAssertEqual(ini["section1", "key1"], "value1")
        XCTAssertEqual(ini["section2", "key2"], "value2")
        XCTAssertEqual(ini["section3", "key3"], "value3")
    }

    func testDictionaryLiteral() {
        let ini: INI = [
            "": ["global_key": "global_value"],
            "section1": ["key1": "value1", "key2": "value2"],
        ]

        XCTAssertEqual(ini.global["global_key"], "global_value")
        XCTAssertEqual(ini["section1", "key1"], "value1")
        XCTAssertEqual(ini["section1", "key2"], "value2")
    }

    // MARK: - Decoding Tests

    func testDecodeSimpleINI() throws {
        let iniString = """
            key1 = value1
            key2 = value2

            [section1]
            key3 = value3
            key4 = value4
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "value1")
        XCTAssertEqual(ini.global["key2"], "value2")
        XCTAssertEqual(ini["section1", "key3"], "value3")
        XCTAssertEqual(ini["section1", "key4"], "value4")
    }

    func testDecodeWithComments() throws {
        let iniString = """
            ; This is a comment
            key1 = value1
            # This is also a comment
            key2 = value2

            [section1]
            ; Section comment
            key3 = value3
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "value1")
        XCTAssertEqual(ini.global["key2"], "value2")
        XCTAssertEqual(ini["section1", "key3"], "value3")
    }

    func testDecodeWithInlineComments() throws {
        let iniString = """
            key1 = value1 ; inline comment
            key2 = value2 # another inline comment
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "value1")
        XCTAssertEqual(ini.global["key2"], "value2")
    }

    func testDecodeQuotedValues() throws {
        let iniString = """
            key1 = "quoted value"
            key2 = 'single quoted'
            key3 = "value with ; semicolon"
            key4 = "value with # hash"
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "quoted value")
        XCTAssertEqual(ini.global["key2"], "single quoted")
        XCTAssertEqual(ini.global["key3"], "value with ; semicolon")
        XCTAssertEqual(ini.global["key4"], "value with # hash")
    }

    func testDecodeEscapeSequences() throws {
        let iniString = """
            key1 = "line1\\nline2"
            key2 = "tab\\there"
            key3 = "quote\\"here"
            key4 = "backslash\\\\here"
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "line1\nline2")
        XCTAssertEqual(ini.global["key2"], "tab\there")
        XCTAssertEqual(ini.global["key3"], "quote\"here")
        XCTAssertEqual(ini.global["key4"], "backslash\\here")
    }

    func testDecodeColonSeparator() throws {
        let iniString = """
            key1: value1
            key2: value2
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "value1")
        XCTAssertEqual(ini.global["key2"], "value2")
    }

    func testDecodeKeysWithoutValues() throws {
        let iniString = """
            key1
            key2 = value2
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "")
        XCTAssertEqual(ini.global["key2"], "value2")
    }

    func testDecodeMultipleSections() throws {
        let iniString = """
            [section1]
            key1 = value1

            [section2]
            key2 = value2

            [section3]
            key3 = value3
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.sectionNames.sorted(), ["section1", "section2", "section3"])
        XCTAssertEqual(ini["section1", "key1"], "value1")
        XCTAssertEqual(ini["section2", "key2"], "value2")
        XCTAssertEqual(ini["section3", "key3"], "value3")
    }

    func testDecodeWithWhitespace() throws {
        let iniString = """
              key1  =  value1
            key2=value2

            [  section1  ]
              key3  =  value3
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "value1")
        XCTAssertEqual(ini.global["key2"], "value2")
        XCTAssertEqual(ini["section1", "key3"], "value3")
    }

    func testDecodeDuplicateKeys() throws {
        let iniString = """
            key1 = value1
            key1 = value2
            """

        // With default options (allow duplicates), last one wins
        let ini = try INI(string: iniString)
        XCTAssertEqual(ini.global["key1"], "value2")
    }

    func testDecodeDuplicateKeysError() throws {
        let iniString = """
            key1 = value1
            key1 = value2
            """

        var options = INIDecoder.Options()
        options.allowDuplicateKeys = false

        XCTAssertThrowsError(try INI(string: iniString, options: options)) { error in
            if case INIDecoder.DecodingError.duplicateKey(let section, let key, let line) = error {
                XCTAssertEqual(section, "")
                XCTAssertEqual(key, "key1")
                XCTAssertEqual(line, 2)
            } else {
                XCTFail("Expected duplicateKey error")
            }
        }
    }

    func testDecodeInvalidSection() throws {
        let iniString = """
            [invalid section
            key = value
            """

        XCTAssertThrowsError(try INI(string: iniString)) { error in
            if case INIDecoder.DecodingError.invalidSection = error {
                // Expected error
            } else {
                XCTFail("Expected invalidSection error")
            }
        }
    }

    func testDecodeEmptySection() throws {
        let iniString = """
            [section1]

            [section2]
            key = value
            """

        let ini = try INI(string: iniString)

        // Empty sections are not created if they have no properties
        XCTAssertNil(ini["section1"])
        XCTAssertEqual(ini["section2", "key"], "value")
    }

    // MARK: - Encoding Tests

    func testEncodeSimpleINI() {
        var ini = INI()
        ini.global["key1"] = "value1"
        ini.global["key2"] = "value2"
        ini["section1", "key3"] = "value3"

        let encoded = ini.encode()

        XCTAssertTrue(encoded.contains("key1 = value1"))
        XCTAssertTrue(encoded.contains("key2 = value2"))
        XCTAssertTrue(encoded.contains("[section1]"))
        XCTAssertTrue(encoded.contains("key3 = value3"))
    }

    func testEncodeMultipleSections() {
        var ini = INI()
        ini["section1", "key1"] = "value1"
        ini["section2", "key2"] = "value2"
        ini["section3", "key3"] = "value3"

        let encoded = ini.encode()

        XCTAssertTrue(encoded.contains("[section1]"))
        XCTAssertTrue(encoded.contains("[section2]"))
        XCTAssertTrue(encoded.contains("[section3]"))
        XCTAssertTrue(encoded.contains("key1 = value1"))
        XCTAssertTrue(encoded.contains("key2 = value2"))
        XCTAssertTrue(encoded.contains("key3 = value3"))
    }

    func testEncodeWithSpecialCharacters() {
        var ini = INI()
        ini.global["key1"] = "value with ; semicolon"
        ini.global["key2"] = "value with # hash"
        ini.global["key3"] = "value with = equals"

        let encoded = ini.encode()

        // Values with special characters should be quoted
        XCTAssertTrue(encoded.contains("\"value with ; semicolon\""))
        XCTAssertTrue(encoded.contains("\"value with # hash\""))
        XCTAssertTrue(encoded.contains("\"value with = equals\""))
    }

    func testEncodeWithWhitespace() {
        var ini = INI()
        ini.global["key1"] = "  leading spaces"
        ini.global["key2"] = "trailing spaces  "
        ini.global["key3"] = "  both  "

        let encoded = ini.encode()

        // Values with leading/trailing whitespace should be quoted
        XCTAssertTrue(encoded.contains("\"  leading spaces\""))
        XCTAssertTrue(encoded.contains("\"trailing spaces  \""))
        XCTAssertTrue(encoded.contains("\"  both  \""))
    }

    func testEncodeWithNewlines() {
        var ini = INI()
        ini.global["key1"] = "line1\nline2"

        let encoded = ini.encode()

        // Newlines should be escaped
        XCTAssertTrue(encoded.contains("\"line1\\nline2\""))
    }

    func testEncodeCustomSeparator() {
        var ini = INI()
        ini.global["key1"] = "value1"

        var options = INIEncoder.Options()
        options.separator = ":"

        let encoded = ini.encode(options: options)

        XCTAssertTrue(encoded.contains("key1:value1"))
    }

    func testEncodeWithoutBlankLines() {
        var ini = INI()
        ini["section1", "key1"] = "value1"
        ini["section2", "key2"] = "value2"

        var options = INIEncoder.Options()
        options.addBlankLineBetweenSections = false

        let encoded = ini.encode(options: options)

        // Should not have blank lines between sections
        XCTAssertFalse(encoded.contains("[section1]\nkey1 = value1\n\n[section2]"))
    }

    func testEncodeWindowsLineEndings() {
        var ini = INI()
        ini.global["key1"] = "value1"

        var options = INIEncoder.Options()
        options.lineEnding = .crlf

        let encoded = ini.encode(options: options)

        XCTAssertTrue(encoded.contains("\r\n"))
    }

    func testEncodeUnsorted() {
        var ini = INI()
        ini["zebra", "key"] = "value"
        ini["alpha", "key"] = "value"

        var options = INIEncoder.Options()
        options.sortSections = false

        // Note: Dictionary order is not guaranteed, so we just test that the option works
        let encoded = ini.encode(options: options)
        XCTAssertTrue(encoded.contains("[zebra]"))
        XCTAssertTrue(encoded.contains("[alpha]"))
    }

    // MARK: - Round-trip Tests

    func testRoundTripSimple() throws {
        let original = """
            key1 = value1
            key2 = value2

            [section1]
            key3 = value3
            key4 = value4
            """

        let ini = try INI(string: original)
        let encoded = ini.encode()
        let decoded = try INI(string: encoded)

        XCTAssertEqual(ini, decoded)
    }

    func testRoundTripComplex() throws {
        var ini = INI()
        ini.global["global_key1"] = "global_value1"
        ini.global["global_key2"] = "global_value2"
        ini["section1", "key1"] = "value1"
        ini["section1", "key2"] = "value with ; comment char"
        ini["section2", "key3"] = "value3"
        ini["section2", "key4"] = "  spaces  "

        let encoded = ini.encode()
        let decoded = try INI(string: encoded)

        XCTAssertEqual(ini, decoded)
    }

    func testRoundTripQuotedValues() throws {
        var ini = INI()
        ini.global["key1"] = "value with ; semicolon"
        ini.global["key2"] = "value with # hash"
        ini.global["key3"] = "line1\nline2"

        let encoded = ini.encode()
        let decoded = try INI(string: encoded)

        XCTAssertEqual(ini, decoded)
    }

    // MARK: - Real-world Examples

    func testRealWorldExample() throws {
        let iniString = """
            ; Configuration file
            app_name = My Application
            version = 1.0.0

            [database]
            host = localhost
            port = 5432
            username = admin
            password = secret123

            [logging]
            level = debug
            file = /var/log/app.log

            [features]
            enable_cache = true
            enable_debug = false
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["app_name"], "My Application")
        XCTAssertEqual(ini.global["version"], "1.0.0")
        XCTAssertEqual(ini["database", "host"], "localhost")
        XCTAssertEqual(ini["database", "port"], "5432")
        XCTAssertEqual(ini["logging", "level"], "debug")
        XCTAssertEqual(ini["features", "enable_cache"], "true")
    }

    func testGitConfigExample() throws {
        let iniString = """
            [core]
            repositoryformatversion = 0
            filemode = true
            bare = false

            [remote "origin"]
            url = https://github.com/user/repo.git
            fetch = +refs/heads/*:refs/remotes/origin/*

            [branch "main"]
            remote = origin
            merge = refs/heads/main
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini["core", "repositoryformatversion"], "0")
        XCTAssertEqual(ini["core", "filemode"], "true")
        XCTAssertEqual(ini["remote \"origin\"", "url"], "https://github.com/user/repo.git")
        XCTAssertEqual(ini["branch \"main\"", "remote"], "origin")
    }

    // MARK: - Edge Cases

    func testEmptyValue() throws {
        let iniString = """
            key1 =
            key2 = ""
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key1"], "")
        XCTAssertEqual(ini.global["key2"], "")
    }

    func testSpacesInKeys() throws {
        let iniString = """
            key with spaces = value
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key with spaces"], "value")
    }

    func testUnicodeCharacters() throws {
        let iniString = """
            name = José
            greeting = 你好
            emoji = 🎉
            """

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["name"], "José")
        XCTAssertEqual(ini.global["greeting"], "你好")
        XCTAssertEqual(ini.global["emoji"], "🎉")
    }

    func testVeryLongValues() throws {
        let longValue = String(repeating: "a", count: 10000)
        let iniString = "key = \(longValue)"

        let ini = try INI(string: iniString)

        XCTAssertEqual(ini.global["key"], longValue)
    }

    func testSectionEquality() {
        let section1: INI.Section = ["key1": "value1", "key2": "value2"]
        let section2: INI.Section = ["key1": "value1", "key2": "value2"]
        let section3: INI.Section = ["key1": "value1", "key2": "different"]

        XCTAssertEqual(section1, section2)
        XCTAssertNotEqual(section1, section3)
    }

    func testINIEquality() {
        var ini1 = INI()
        ini1["section", "key"] = "value"

        var ini2 = INI()
        ini2["section", "key"] = "value"

        var ini3 = INI()
        ini3["section", "key"] = "different"

        XCTAssertEqual(ini1, ini2)
        XCTAssertNotEqual(ini1, ini3)
    }

    func testDataEncoding() throws {
        var ini = INI()
        ini.global["key"] = "value"

        let data = ini.encodeData()
        let decoded = try INI(data: data)

        XCTAssertEqual(ini, decoded)
    }
}
