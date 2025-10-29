// INITests.swift
// Comprehensive tests for the INI library

import Testing

@testable import INI

// MARK: - Basic Structure Tests

@Test func emptyINI() {
    let ini = INI()
    #expect(ini.isEmpty)
    #expect(ini.sectionNames == [])
}

@Test func globalSection() {
    var ini = INI()
    ini.global["key1"] = "value1"
    ini.global["key2"] = "value2"

    #expect(ini.global["key1"] == "value1")
    #expect(ini.global["key2"] == "value2")
    #expect(!ini.isEmpty)
}

@Test func namedSection() {
    var ini = INI()
    ini["section1", "key1"] = "value1"
    ini["section1", "key2"] = "value2"

    #expect(ini["section1", "key1"] == "value1")
    #expect(ini["section1", "key2"] == "value2")
    #expect(ini.sectionNames == ["section1"])
}

@Test func multipleSections() {
    var ini = INI()
    ini["section1", "key1"] = "value1"
    ini["section2", "key2"] = "value2"
    ini["section3", "key3"] = "value3"

    #expect(ini.sectionNames.sorted() == ["section1", "section2", "section3"])
    #expect(ini["section1", "key1"] == "value1")
    #expect(ini["section2", "key2"] == "value2")
    #expect(ini["section3", "key3"] == "value3")
}

@Test func dictionaryLiteral() {
    let ini: INI = [
        "": ["global_key": "global_value"],
        "section1": ["key1": "value1", "key2": "value2"],
    ]

    #expect(ini.global["global_key"] == "global_value")
    #expect(ini["section1", "key1"] == "value1")
    #expect(ini["section1", "key2"] == "value2")
}

// MARK: - Decoding Tests

@Test func decodeSimpleINI() throws {
    let iniString = """
        key1 = value1
        key2 = value2

        [section1]
        key3 = value3
        key4 = value4
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["key1"] == "value1")
    #expect(ini.global["key2"] == "value2")
    #expect(ini["section1", "key3"] == "value3")
    #expect(ini["section1", "key4"] == "value4")
}

@Test func decodeWithComments() throws {
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

    #expect(ini.global["key1"] == "value1")
    #expect(ini.global["key2"] == "value2")
    #expect(ini["section1", "key3"] == "value3")
}

@Test func decodeWithInlineComments() throws {
    let iniString = """
        key1 = value1 ; inline comment
        key2 = value2 # another inline comment
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["key1"] == "value1")
    #expect(ini.global["key2"] == "value2")
}

@Test func decodeQuotedValues() throws {
    let iniString = """
        key1 = "quoted value"
        key2 = 'single quoted'
        key3 = "value with ; semicolon"
        key4 = "value with # hash"
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["key1"] == "quoted value")
    #expect(ini.global["key2"] == "single quoted")
    #expect(ini.global["key3"] == "value with ; semicolon")
    #expect(ini.global["key4"] == "value with # hash")
}

@Test func decodeEscapeSequences() throws {
    let iniString = """
        key1 = "line1\\nline2"
        key2 = "tab\\there"
        key3 = "quote\\"here"
        key4 = "backslash\\\\here"
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["key1"] == "line1\nline2")
    #expect(ini.global["key2"] == "tab\there")
    #expect(ini.global["key3"] == "quote\"here")
    #expect(ini.global["key4"] == "backslash\\here")
}

@Test func decodeColonSeparator() throws {
    let iniString = """
        key1: value1
        key2: value2
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["key1"] == "value1")
    #expect(ini.global["key2"] == "value2")
}

@Test func decodeKeysWithoutValues() throws {
    let iniString = """
        key1
        key2 = value2
        """

    var options = INIDecoder.Options()
    options.allowArraySections = false
    options.allowKeysWithoutValues = true

    let ini = try INI(string: iniString, options: options)

    #expect(ini.global["key1"] == "")
    #expect(ini.global["key2"] == "value2")
}

@Test func decodeMultipleSections() throws {
    let iniString = """
        [section1]
        key1 = value1

        [section2]
        key2 = value2

        [section3]
        key3 = value3
        """

    let ini = try INI(string: iniString)

    #expect(ini.sectionNames.sorted() == ["section1", "section2", "section3"])
    #expect(ini["section1", "key1"] == "value1")
    #expect(ini["section2", "key2"] == "value2")
    #expect(ini["section3", "key3"] == "value3")
}

@Test func decodeWithWhitespace() throws {
    let iniString = """
          key1  =  value1
        key2=value2

        [  section1  ]
          key3  =  value3
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["key1"] == "value1")
    #expect(ini.global["key2"] == "value2")
    #expect(ini["section1", "key3"] == "value3")
}

@Test func decodeDuplicateKeys() throws {
    let iniString = """
        key1 = value1
        key1 = value2
        """

    // With default options (allow duplicates), last one wins
    let ini = try INI(string: iniString)
    #expect(ini.global["key1"] == "value2")
}

@Test func decodeDuplicateKeysError() throws {
    let iniString = """
        key1 = value1
        key1 = value2
        """

    var options = INIDecoder.Options()
    options.allowDuplicateKeys = false

    #expect(throws: INIDecoder.DecodingError.self) {
        try INI(string: iniString, options: options)
    }
}

@Test func decodeInvalidSection() throws {
    let iniString = """
        [invalid section
        key = value
        """

    #expect(throws: INIDecoder.DecodingError.self) {
        try INI(string: iniString)
    }
}

@Test func decodeEmptySection() throws {
    let iniString = """
        [section1]

        [section2]
        key = value
        """

    let ini = try INI(string: iniString)

    // Empty sections are not created if they have no properties
    #expect(ini["section1"] == nil)
    #expect(ini["section2", "key"] == "value")
}

// MARK: - Encoding Tests

@Test func encodeSimpleINI() {
    var ini = INI()
    ini.global["key1"] = "value1"
    ini.global["key2"] = "value2"
    ini["section1", "key3"] = "value3"

    let encoded = ini.encode()

    #expect(encoded.contains("key1 = value1"))
    #expect(encoded.contains("key2 = value2"))
    #expect(encoded.contains("[section1]"))
    #expect(encoded.contains("key3 = value3"))
}

@Test func encodeMultipleSections() {
    var ini = INI()
    ini["section1", "key1"] = "value1"
    ini["section2", "key2"] = "value2"
    ini["section3", "key3"] = "value3"

    let encoded = ini.encode()

    #expect(encoded.contains("[section1]"))
    #expect(encoded.contains("[section2]"))
    #expect(encoded.contains("[section3]"))
    #expect(encoded.contains("key1 = value1"))
    #expect(encoded.contains("key2 = value2"))
    #expect(encoded.contains("key3 = value3"))
}

@Test func encodeWithSpecialCharacters() {
    var ini = INI()
    ini.global["key1"] = "value with ; semicolon"
    ini.global["key2"] = "value with # hash"
    ini.global["key3"] = "value with = equals"

    let encoded = ini.encode()

    // Values with special characters should be quoted
    #expect(encoded.contains("\"value with ; semicolon\""))
    #expect(encoded.contains("\"value with # hash\""))
    #expect(encoded.contains("\"value with = equals\""))
}

@Test func encodeWithWhitespace() {
    var ini = INI()
    ini.global["key1"] = "  leading spaces"
    ini.global["key2"] = "trailing spaces  "
    ini.global["key3"] = "  both  "

    let encoded = ini.encode()

    // Values with leading/trailing whitespace should be quoted
    #expect(encoded.contains("\"  leading spaces\""))
    #expect(encoded.contains("\"trailing spaces  \""))
    #expect(encoded.contains("\"  both  \""))
}

@Test func encodeWithNewlines() {
    var ini = INI()
    ini.global["key1"] = "line1\nline2"

    let encoded = ini.encode()

    // Newlines should be escaped
    #expect(encoded.contains("\"line1\\nline2\""))
}

@Test func encodeCustomSeparator() {
    var ini = INI()
    ini.global["key1"] = "value1"

    var options = INIEncoder.Options()
    options.separator = ":"

    let encoded = ini.encode(options: options)

    #expect(encoded.contains("key1:value1"))
}

@Test func encodeWithoutBlankLines() {
    var ini = INI()
    ini["section1", "key1"] = "value1"
    ini["section2", "key2"] = "value2"

    var options = INIEncoder.Options()
    options.addBlankLineBetweenSections = false

    let encoded = ini.encode(options: options)

    // Should not have blank lines between sections
    #expect(!encoded.contains("[section1]\nkey1 = value1\n\n[section2]"))
}

@Test func encodeWindowsLineEndings() {
    var ini = INI()
    ini.global["key1"] = "value1"

    var options = INIEncoder.Options()
    options.lineEnding = .crlf

    let encoded = ini.encode(options: options)

    #expect(encoded.contains("\r\n"))
}

@Test func encodeUnsorted() {
    var ini = INI()
    ini["zebra", "key"] = "value"
    ini["alpha", "key"] = "value"

    var options = INIEncoder.Options()
    options.sortSections = false

    // Note: Dictionary order is not guaranteed, so we just test that the option works
    let encoded = ini.encode(options: options)
    #expect(encoded.contains("[zebra]"))
    #expect(encoded.contains("[alpha]"))
}

// MARK: - Round-trip Tests

@Test func roundTripSimple() throws {
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

    #expect(ini == decoded)
}

@Test func roundTripComplex() throws {
    var ini = INI()
    ini.global["global_key1"] = "global_value1"
    ini.global["global_key2"] = "global_value2"
    ini["section1", "key1"] = "value1"
    ini["section1", "key2"] = "value with ; comment char"
    ini["section2", "key3"] = "value3"
    ini["section2", "key4"] = "  spaces  "

    let encoded = ini.encode()
    let decoded = try INI(string: encoded)

    #expect(ini == decoded)
}

@Test func roundTripQuotedValues() throws {
    var ini = INI()
    ini.global["key1"] = "value with ; semicolon"
    ini.global["key2"] = "value with # hash"
    ini.global["key3"] = "line1\nline2"

    let encoded = ini.encode()
    let decoded = try INI(string: encoded)

    #expect(ini == decoded)
}

// MARK: - Real-world Examples

@Test func realWorldExample() throws {
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

    #expect(ini.global["app_name"] == "My Application")
    #expect(ini.global["version"] == "1.0.0")
    #expect(ini["database", "host"] == "localhost")
    #expect(ini["database", "port"] == "5432")
    #expect(ini["logging", "level"] == "debug")
    #expect(ini["features", "enable_cache"] == "true")
}

@Test func gitConfigExample() throws {
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

    #expect(ini["core", "repositoryformatversion"] == "0")
    #expect(ini["core", "filemode"] == "true")
    #expect(ini["remote \"origin\"", "url"] == "https://github.com/user/repo.git")
    #expect(ini["branch \"main\"", "remote"] == "origin")
}

// MARK: - Edge Cases

@Test func emptyValue() throws {
    let iniString = """
        key1 =
        key2 = ""
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["key1"] == "")
    #expect(ini.global["key2"] == "")
}

@Test func spacesInKeys() throws {
    let iniString = """
        key with spaces = value
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["key with spaces"] == "value")
}

@Test func unicodeCharacters() throws {
    let iniString = """
        name = José
        greeting = 你好
        emoji = 🎉
        """

    let ini = try INI(string: iniString)

    #expect(ini.global["name"] == "José")
    #expect(ini.global["greeting"] == "你好")
    #expect(ini.global["emoji"] == "🎉")
}

@Test func veryLongValues() throws {
    let longValue = String(repeating: "a", count: 10000)
    let iniString = "key = \(longValue)"

    let ini = try INI(string: iniString)

    #expect(ini.global["key"] == longValue)
}

@Test func sectionEquality() {
    let section1: INI.Section = ["key1": "value1", "key2": "value2"]
    let section2: INI.Section = ["key1": "value1", "key2": "value2"]
    let section3: INI.Section = ["key1": "value1", "key2": "different"]

    #expect(section1 == section2)
    #expect(section1 != section3)
}

@Test func iniEquality() {
    var ini1 = INI()
    ini1["section", "key"] = "value"

    var ini2 = INI()
    ini2["section", "key"] = "value"

    var ini3 = INI()
    ini3["section", "key"] = "different"

    #expect(ini1 == ini2)
    #expect(ini1 != ini3)
}

@Test func dataEncoding() throws {
    var ini = INI()
    ini.global["key"] = "value"

    let data = ini.encodeData()
    let decoded = try INI(data: data)

    #expect(ini == decoded)
}

// MARK: - Section Prefix Tests

@Test func sectionsWithPrefixNoMatches() {
    var ini = INI()
    ini["section1", "key1"] = "value1"
    ini["section2", "key2"] = "value2"
    ini["other", "key3"] = "value3"

    let matches = ini.sections(withPrefix: "prefix")

    #expect(matches.isEmpty)
}

@Test func sectionsWithPrefixSomeMatches() {
    var ini = INI()
    ini["remote.origin", "url"] = "https://github.com/user/repo1.git"
    ini["remote.upstream", "url"] = "https://github.com/user/repo2.git"
    ini["branch.main", "remote"] = "origin"
    ini["core", "filemode"] = "true"

    let matches = ini.sections(withPrefix: "remote.")

    #expect(matches.count == 2)
    #expect(matches[0].name == "remote.origin")
    #expect(matches[0].section["url"] == "https://github.com/user/repo1.git")
    #expect(matches[1].name == "remote.upstream")
    #expect(matches[1].section["url"] == "https://github.com/user/repo2.git")
}

@Test func sectionsWithPrefixAllMatch() {
    var ini = INI()
    ini["prefix1", "key1"] = "value1"
    ini["prefix2", "key2"] = "value2"
    ini["prefix3", "key3"] = "value3"

    let matches = ini.sections(withPrefix: "prefix")

    #expect(matches.count == 3)
    #expect(matches[0].name == "prefix1")
    #expect(matches[1].name == "prefix2")
    #expect(matches[2].name == "prefix3")
}

@Test func sectionsWithPrefixSorted() {
    var ini = INI()
    ini["remote.zebra", "key"] = "value"
    ini["remote.alpha", "key"] = "value"
    ini["remote.beta", "key"] = "value"

    let matches = ini.sections(withPrefix: "remote.")

    #expect(matches.count == 3)
    #expect(matches[0].name == "remote.alpha")
    #expect(matches[1].name == "remote.beta")
    #expect(matches[2].name == "remote.zebra")
}

@Test func sectionsWithPrefixExcludesGlobal() {
    var ini = INI()
    ini.global["key"] = "value"
    ini["section", "key"] = "value"

    // Empty prefix should not match global section
    let matches = ini.sections(withPrefix: "")

    #expect(matches.count == 1)
    #expect(matches[0].name == "section")
}

@Test func sectionsWithPrefixEmptyINI() {
    let ini = INI()

    let matches = ini.sections(withPrefix: "any")

    #expect(matches.isEmpty)
}

@Test func sectionsWithPrefixGitConfigStyle() throws {
    let iniString = """
        [core]
        repositoryformatversion = 0

        [remote "origin"]
        url = https://github.com/user/repo1.git
        fetch = +refs/heads/*:refs/remotes/origin/*

        [remote "upstream"]
        url = https://github.com/user/repo2.git

        [branch "main"]
        remote = origin
        merge = refs/heads/main

        [branch "develop"]
        remote = origin
        merge = refs/heads/develop
        """

    let ini = try INI(string: iniString)

    let remotes = ini.sections(withPrefix: "remote ")
    #expect(remotes.count == 2)
    #expect(remotes[0].name == "remote \"origin\"")
    #expect(remotes[1].name == "remote \"upstream\"")

    let branches = ini.sections(withPrefix: "branch ")
    #expect(branches.count == 2)
    #expect(branches[0].name == "branch \"develop\"")
    #expect(branches[1].name == "branch \"main\"")
}

@Test func sectionsWithPrefixExactMatch() {
    var ini = INI()
    ini["prefix", "key1"] = "value1"
    ini["prefix.sub", "key2"] = "value2"

    // Should match both (exact match is also a prefix match)
    let matches = ini.sections(withPrefix: "prefix")

    #expect(matches.count == 2)
    #expect(matches[0].name == "prefix")
    #expect(matches[1].name == "prefix.sub")
}
