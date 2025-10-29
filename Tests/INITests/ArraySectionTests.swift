// ArraySectionTests.swift
// Tests for array-style sections in INI files

import Testing

@testable import INI

// MARK: - Array Section Tests

@Test func decodeSimpleArraySection() throws {
    let iniString = """
        [allowed_ips]
        192.168.1.1
        192.168.1.2
        192.168.1.3
        """

    let ini = try INI(string: iniString)

    #expect(ini.sectionNames == ["allowed_ips"])

    let section = ini["allowed_ips"]
    #expect(section != nil)
    #expect(section?.isArray == true)
    #expect(section?.array == ["192.168.1.1", "192.168.1.2", "192.168.1.3"])
    #expect(section?.count == 3)
}

@Test func decodeMultipleArraySections() throws {
    let iniString = """
        [allowed_ips]
        192.168.1.1
        192.168.1.2

        [allowed_domains]
        example.com
        test.com
        demo.org
        """

    let ini = try INI(string: iniString)

    #expect(ini.sectionNames.sorted() == ["allowed_domains", "allowed_ips"])

    let ipsSection = ini["allowed_ips"]
    #expect(ipsSection?.isArray == true)
    #expect(ipsSection?.array == ["192.168.1.1", "192.168.1.2"])

    let domainsSection = ini["allowed_domains"]
    #expect(domainsSection?.isArray == true)
    #expect(domainsSection?.array == ["example.com", "test.com", "demo.org"])
}

@Test func decodeMixedKeyValueAndArraySections() throws {
    let iniString = """
        [database]
        host = localhost
        port = 5432

        [allowed_ips]
        192.168.1.1
        192.168.1.2
        192.168.1.3

        [cache]
        enabled = true
        ttl = 3600
        """

    let ini = try INI(string: iniString)

    // Check database section (key-value)
    let dbSection = ini["database"]
    #expect(dbSection?.isArray == false)
    #expect(dbSection?["host"] == "localhost")
    #expect(dbSection?["port"] == "5432")

    // Check allowed_ips section (array)
    let ipsSection = ini["allowed_ips"]
    #expect(ipsSection?.isArray == true)
    #expect(ipsSection?.array == ["192.168.1.1", "192.168.1.2", "192.168.1.3"])

    // Check cache section (key-value)
    let cacheSection = ini["cache"]
    #expect(cacheSection?.isArray == false)
    #expect(cacheSection?["enabled"] == "true")
    #expect(cacheSection?["ttl"] == "3600")
}

@Test func decodeGlobalArraySection() throws {
    let iniString = """
        item1
        item2
        item3

        [section1]
        key = value
        """

    let ini = try INI(string: iniString)

    #expect(ini.global.isArray == true)
    #expect(ini.global.array == ["item1", "item2", "item3"])
    #expect(ini.global.count == 3)

    let section = ini["section1"]
    #expect(section?.isArray == false)
    #expect(section?["key"] == "value")
}

@Test func decodeArraySectionWithComments() throws {
    let iniString = """
        [allowed_ips]
        ; This is a comment
        192.168.1.1
        ; Another comment
        192.168.1.2
        192.168.1.3  ; inline comment
        """

    let ini = try INI(string: iniString)

    let section = ini["allowed_ips"]
    #expect(section?.isArray == true)
    #expect(section?.array == ["192.168.1.1", "192.168.1.2", "192.168.1.3"])
}

@Test func decodeArraySectionWithWhitespace() throws {
    let iniString = """
        [items]
          item1
        item2
          item3
        """

    let ini = try INI(string: iniString)

    let section = ini["items"]
    #expect(section?.isArray == true)
    // Whitespace should be trimmed by default
    #expect(section?.array == ["item1", "item2", "item3"])
}

@Test func decodeEmptyArraySection() throws {
    let iniString = """
        [empty_section]

        [section_with_data]
        key = value
        """

    let ini = try INI(string: iniString)

    // Empty sections might not be created
    let emptySection = ini["empty_section"]
    #expect(emptySection == nil || emptySection?.isEmpty == true)
}

@Test func encodeSimpleArraySection() {
    var ini = INI()
    var section = INI.Section(["item1", "item2", "item3"])
    ini["items"] = section

    let encoded = ini.encode()

    #expect(encoded.contains("[items]"))
    #expect(encoded.contains("item1"))
    #expect(encoded.contains("item2"))
    #expect(encoded.contains("item3"))
    #expect(!encoded.contains("="))
}

@Test func encodeMixedSections() {
    var ini = INI()

    // Add key-value section
    ini["config", "host"] = "localhost"
    ini["config", "port"] = "8080"

    // Add array section
    var arraySection = INI.Section(["192.168.1.1", "192.168.1.2"])
    ini["allowed_ips"] = arraySection

    let encoded = ini.encode()

    #expect(encoded.contains("[config]"))
    #expect(encoded.contains("host = localhost"))
    #expect(encoded.contains("port = 8080"))
    #expect(encoded.contains("[allowed_ips]"))
    #expect(encoded.contains("192.168.1.1"))
    #expect(encoded.contains("192.168.1.2"))
}

@Test func roundTripArraySection() throws {
    let original = """
        [database]
        host = localhost
        port = 5432

        [allowed_ips]
        192.168.1.1
        192.168.1.2
        192.168.1.3
        """

    let ini = try INI(string: original)
    let encoded = ini.encode()
    let decoded = try INI(string: encoded)

    // Verify database section
    #expect(decoded["database", "host"] == "localhost")
    #expect(decoded["database", "port"] == "5432")

    // Verify array section
    let ipsSection = decoded["allowed_ips"]
    #expect(ipsSection?.isArray == true)
    #expect(ipsSection?.array == ["192.168.1.1", "192.168.1.2", "192.168.1.3"])
}

@Test func arraySectionIsEmpty() {
    let emptyArray = INI.Section([])
    #expect(emptyArray.isEmpty)
    #expect(emptyArray.isArray)
    #expect(emptyArray.count == 0)

    let nonEmptyArray = INI.Section(["item1"])
    #expect(!nonEmptyArray.isEmpty)
    #expect(nonEmptyArray.isArray)
    #expect(nonEmptyArray.count == 1)
}

@Test func arraySectionCount() {
    let section = INI.Section(["a", "b", "c", "d"])
    #expect(section.count == 4)
    #expect(section.isArray)
}

@Test func setArrayOnSection() {
    var section = INI.Section()
    #expect(!section.isArray)

    section.array = ["item1", "item2"]
    #expect(section.isArray)
    #expect(section.array == ["item1", "item2"])
}

@Test func convertKeyValueToArray() {
    var section = INI.Section(["key1": "value1", "key2": "value2"])
    #expect(!section.isArray)

    section.array = ["item1", "item2"]
    #expect(section.isArray)
    #expect(section.array == ["item1", "item2"])
    // Setting array should clear key-value pairs
    #expect(section["key1"] == nil)
}

@Test func convertArrayToKeyValue() {
    var section = INI.Section(["item1", "item2"])
    #expect(section.isArray)

    section["key1"] = "value1"
    #expect(!section.isArray)
    #expect(section["key1"] == "value1")
    #expect(section.array == [])
}

@Test func arrayAccessOnKeyValueSection() {
    let section = INI.Section(["key": "value"])
    #expect(!section.isArray)
    #expect(section.array == [])
}

@Test func decodeArrayWithSpecialCharacters() throws {
    let iniString = """
        [items]
        item with spaces
        item;with;semicolons
        item#with#hashes
        """

    let ini = try INI(string: iniString)

    let section = ini["items"]
    #expect(section?.isArray == true)
    #expect(section?.array == ["item with spaces", "item;with;semicolons", "item#with#hashes"])
}

@Test func decodeArrayWithUnicodeCharacters() throws {
    let iniString = """
        [unicode_items]
        こんにちは
        مرحبا
        Привет
        🎉
        """

    let ini = try INI(string: iniString)

    let section = ini["unicode_items"]
    #expect(section?.isArray == true)
    #expect(section?.array == ["こんにちは", "مرحبا", "Привет", "🎉"])
}

@Test func globalArraySection() {
    var ini = INI()
    ini.global = INI.Section(["item1", "item2", "item3"])

    #expect(ini.global.isArray)
    #expect(ini.global.array == ["item1", "item2", "item3"])

    let encoded = ini.encode()
    #expect(encoded.contains("item1"))
    #expect(encoded.contains("item2"))
    #expect(encoded.contains("item3"))
    #expect(!encoded.contains("["))
}

@Test func arrayDescriptionInINI() {
    var ini = INI()
    ini["items"] = INI.Section(["a", "b", "c"])

    let description = ini.description
    #expect(description.contains("[items]"))
    #expect(description.contains("a"))
    #expect(description.contains("b"))
    #expect(description.contains("c"))
}

@Test func realWorldArrayExample() throws {
    let config = """
        [app]
        name = My Application
        version = 1.0.0

        [allowed_origins]
        https://example.com
        https://test.com
        https://demo.org

        [blocked_ips]
        10.0.0.1
        10.0.0.2

        [database]
        host = localhost
        port = 5432
        """

    let ini = try INI(string: config)

    // Check key-value sections
    #expect(ini["app", "name"] == "My Application")
    #expect(ini["app", "version"] == "1.0.0")
    #expect(ini["database", "host"] == "localhost")
    #expect(ini["database", "port"] == "5432")

    // Check array sections
    let originsSection = ini["allowed_origins"]
    #expect(originsSection?.isArray == true)
    #expect(
        originsSection?.array == ["https://example.com", "https://test.com", "https://demo.org"])

    let blockedSection = ini["blocked_ips"]
    #expect(blockedSection?.isArray == true)
    #expect(blockedSection?.array == ["10.0.0.1", "10.0.0.2"])
}

@Test func disableArraySections() throws {
    let iniString = """
        [section]
        item1
        item2
        """

    var options = INIDecoder.Options()
    options.allowArraySections = false
    options.allowKeysWithoutValues = true

    let ini = try INI(string: iniString, options: options)

    let section = ini["section"]
    #expect(section?.isArray == false)
    // With allowArraySections disabled and allowKeysWithoutValues enabled,
    // items should be treated as keys with empty values
    #expect(section?["item1"] == "")
    #expect(section?["item2"] == "")
}
