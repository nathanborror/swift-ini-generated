// INIDecoder.swift
// Decodes INI format strings into INI structures

import Foundation

/// Decodes INI format strings into `INI` structures
public struct INIDecoder {

    /// Options for decoding INI files
    public struct Options: Sendable {
        /// Characters that indicate a comment line (default: [";", "#"])
        public var commentCharacters: Set<Character>

        /// Whether to trim whitespace from keys and values (default: true)
        public var trimWhitespace: Bool

        /// Whether to allow duplicate keys (last one wins) (default: true)
        public var allowDuplicateKeys: Bool

        /// Whether to parse quoted values (default: true)
        public var parseQuotedValues: Bool

        /// Whether to allow keys without values (default: true, value will be empty string)
        public var allowKeysWithoutValues: Bool

        /// Key-value separator characters (default: ["=", ":"])
        public var separatorCharacters: Set<Character>

        /// Whether to allow array-style sections with just items (no key=value pairs) (default: true)
        public var allowArraySections: Bool

        public init(
            commentCharacters: Set<Character> = [";", "#"],
            trimWhitespace: Bool = true,
            allowDuplicateKeys: Bool = true,
            parseQuotedValues: Bool = true,
            allowKeysWithoutValues: Bool = true,
            separatorCharacters: Set<Character> = ["=", ":"],
            allowArraySections: Bool = true
        ) {
            self.commentCharacters = commentCharacters
            self.trimWhitespace = trimWhitespace
            self.allowDuplicateKeys = allowDuplicateKeys
            self.parseQuotedValues = parseQuotedValues
            self.allowKeysWithoutValues = allowKeysWithoutValues
            self.separatorCharacters = separatorCharacters
            self.allowArraySections = allowArraySections
        }
    }

    /// Errors that can occur during decoding
    public enum DecodingError: Error, CustomStringConvertible {
        case invalidSection(line: Int, content: String)
        case invalidKeyValuePair(line: Int, content: String)
        case duplicateKey(section: String, key: String, line: Int)
        case unclosedQuote(line: Int)

        public var description: String {
            switch self {
            case .invalidSection(let line, let content):
                return "Invalid section header at line \(line): \(content)"
            case .invalidKeyValuePair(let line, let content):
                return "Invalid key-value pair at line \(line): \(content)"
            case .duplicateKey(let section, let key, let line):
                let sectionName = section.isEmpty ? "global section" : "section '\(section)'"
                return "Duplicate key '\(key)' in \(sectionName) at line \(line)"
            case .unclosedQuote(let line):
                return "Unclosed quote at line \(line)"
            }
        }
    }

    /// Decoding options
    public var options: Options

    /// Initialize with default options
    public init() {
        self.options = Options()
    }

    /// Initialize with custom options
    public init(options: Options) {
        self.options = options
    }

    /// Decode an INI string into an INI structure
    public func decode(_ string: String) throws -> INI {
        var ini = INI()
        var currentSection = ""  // Empty string represents global section
        var seenKeys: [String: Set<String>] = [:]  // Track keys per section for duplicate detection
        var sectionArrayItems: [String: [String]] = [:]  // Track array items per section

        let lines = string.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines
            if trimmedLine.isEmpty {
                continue
            }

            // Skip comment lines
            if let firstChar = trimmedLine.first, options.commentCharacters.contains(firstChar) {
                continue
            }

            // Check for section header
            if trimmedLine.hasPrefix("[") {
                guard trimmedLine.hasSuffix("]") else {
                    throw DecodingError.invalidSection(line: lineNumber, content: trimmedLine)
                }

                let sectionName = String(trimmedLine.dropFirst().dropLast())
                let finalSectionName =
                    options.trimWhitespace
                    ? sectionName.trimmingCharacters(in: .whitespaces)
                    : sectionName

                guard !finalSectionName.isEmpty else {
                    throw DecodingError.invalidSection(line: lineNumber, content: trimmedLine)
                }

                currentSection = finalSectionName
                continue
            }

            // Try to parse as key-value pair
            if let (key, value) = try parseKeyValue(line: trimmedLine, lineNumber: lineNumber) {
                // Check if this looks like a URL or other non-key-value pattern
                let looksLikeKeyValue = !isLikelyArrayItem(
                    key: key, value: value, line: trimmedLine)

                if options.allowArraySections && !looksLikeKeyValue {
                    // Even though we parsed it as key-value, it's more likely an array item
                    let item = stripInlineCommentFromArrayItem(trimmedLine)
                    sectionArrayItems[currentSection, default: []].append(item)
                } else {
                    // Check for duplicate keys if not allowed
                    if !options.allowDuplicateKeys {
                        if seenKeys[currentSection]?.contains(key) == true {
                            throw DecodingError.duplicateKey(
                                section: currentSection, key: key, line: lineNumber)
                        }
                        seenKeys[currentSection, default: []].insert(key)
                    }

                    // Set the value
                    ini[currentSection, key] = value
                }
            } else if options.allowArraySections {
                // No separator found - treat as array item
                let item = stripInlineCommentFromArrayItem(trimmedLine)
                sectionArrayItems[currentSection, default: []].append(item)
            } else {
                throw DecodingError.invalidKeyValuePair(line: lineNumber, content: trimmedLine)
            }
        }

        // Convert sections with only array items to array sections
        for (sectionName, items) in sectionArrayItems {
            // Check if this section has any key-value pairs
            let hasKeyValuePairs: Bool
            if sectionName.isEmpty {
                hasKeyValuePairs = !ini.global.isEmpty && ini.global.count > 0
            } else {
                hasKeyValuePairs = ini[sectionName]?.count ?? 0 > 0
            }

            // If section has no key-value pairs, convert to array section
            if !hasKeyValuePairs {
                let section = INI.Section(items)
                if sectionName.isEmpty {
                    ini.global = section
                } else {
                    ini[sectionName] = section
                }
            }
        }

        return ini
    }

    /// Decode INI data into an INI structure
    public func decode(_ data: Data) throws -> INI {
        guard let string = String(data: data, encoding: .utf8) else {
            throw DecodingError.invalidKeyValuePair(line: 0, content: "Invalid UTF-8 data")
        }
        return try decode(string)
    }

    // MARK: - Private Methods

    private func parseKeyValue(line: String, lineNumber: Int) throws -> (
        key: String, value: String
    )? {
        // Find the separator
        guard
            let separatorIndex = line.firstIndex(where: { options.separatorCharacters.contains($0) }
            )
        else {
            // No separator found
            // If array sections are enabled, let the caller handle it as an array item
            // Otherwise, treat as key without value if that's allowed
            if options.allowKeysWithoutValues && !options.allowArraySections {
                let key =
                    options.trimWhitespace
                    ? line.trimmingCharacters(in: .whitespaces)
                    : line
                return (key, "")
            }
            return nil
        }

        let keyPart = line[..<separatorIndex]
        let valuePart = line[line.index(after: separatorIndex)...]

        var key = String(keyPart)
        var value = String(valuePart)

        if options.trimWhitespace {
            key = key.trimmingCharacters(in: .whitespaces)
            value = value.trimmingCharacters(in: .whitespaces)
        }

        // Handle inline comments in value
        if let commentIndex = value.firstIndex(where: { options.commentCharacters.contains($0) }) {
            // Check if it's inside quotes
            let beforeComment = value[..<commentIndex]
            let quoteCount = beforeComment.filter { $0 == "\"" || $0 == "'" }.count

            // If odd number of quotes, comment is inside quotes, don't strip
            if quoteCount % 2 == 0 {
                value = String(beforeComment)
                if options.trimWhitespace {
                    value = value.trimmingCharacters(in: .whitespaces)
                }
            }
        }

        // Parse quoted values
        if options.parseQuotedValues {
            value = try parseQuotedValue(value, lineNumber: lineNumber)
        }

        guard !key.isEmpty else {
            return nil
        }

        return (key, value)
    }

    private func parseQuotedValue(_ value: String, lineNumber: Int) throws -> String {
        guard !value.isEmpty else { return value }

        let firstChar = value.first!
        let lastChar = value.last!

        // Check for single or double quotes
        if (firstChar == "\"" && lastChar == "\"") || (firstChar == "'" && lastChar == "'") {
            guard value.count >= 2 else {
                throw DecodingError.unclosedQuote(line: lineNumber)
            }

            var result = String(value.dropFirst().dropLast())

            // Handle escape sequences
            result =
                result
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\r", with: "\r")
                .replacingOccurrences(of: "\\t", with: "\t")
                .replacingOccurrences(of: "\\\\", with: "\\")
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\'", with: "'")

            return result
        }

        return value
    }

    // Check if a parsed key-value pair is more likely an array item (like a URL)
    private func isLikelyArrayItem(key: String, value: String, line: String) -> Bool {
        // If the key looks like a URL protocol (short, lowercase, followed by ://)
        let commonProtocols = ["http", "https", "ftp", "ftps", "ws", "wss", "file"]
        if commonProtocols.contains(key.lowercased()) && value.hasPrefix("//") {
            return true
        }

        return false
    }

    // Strip inline comments from array items (only if preceded by whitespace)
    private func stripInlineCommentFromArrayItem(_ line: String) -> String {
        var result = line

        // Find comment character that's preceded by whitespace
        for (index, char) in result.enumerated() {
            if options.commentCharacters.contains(char) {
                // Check if preceded by whitespace (or is at start of line)
                if index == 0 {
                    // Comment at start - return empty or handle as needed
                    return ""
                } else if index > 0
                    && result[result.index(result.startIndex, offsetBy: index - 1)].isWhitespace
                {
                    // Found comment preceded by whitespace - strip from here
                    result = String(result.prefix(index))
                    if options.trimWhitespace {
                        result = result.trimmingCharacters(in: .whitespaces)
                    }
                    break
                }
                // Otherwise, it's part of the data (like item;with;semicolons), so continue
            }
        }

        return options.trimWhitespace ? result.trimmingCharacters(in: .whitespaces) : result
    }

    // Strip inline comments from a line
    private func stripInlineComment(from line: String) -> String {
        var result = line

        // Find comment character not inside quotes
        if let commentIndex = result.firstIndex(where: { options.commentCharacters.contains($0) }) {
            let beforeComment = result[..<commentIndex]
            let quoteCount = beforeComment.filter { $0 == "\"" || $0 == "'" }.count

            // If even number of quotes, comment is outside quotes, strip it
            if quoteCount % 2 == 0 {
                result = String(beforeComment)
                if options.trimWhitespace {
                    result = result.trimmingCharacters(in: .whitespaces)
                }
            }
        }

        return result
    }
}

// MARK: - Convenience Methods
extension INI {
    /// Decode an INI string using default options
    public init(string: String) throws {
        let decoder = INIDecoder()
        self = try decoder.decode(string)
    }

    /// Decode INI data using default options
    public init(data: Data) throws {
        let decoder = INIDecoder()
        self = try decoder.decode(data)
    }

    /// Decode an INI string with custom options
    public init(string: String, options: INIDecoder.Options) throws {
        let decoder = INIDecoder(options: options)
        self = try decoder.decode(string)
    }

    /// Decode INI data with custom options
    public init(data: Data, options: INIDecoder.Options) throws {
        let decoder = INIDecoder(options: options)
        self = try decoder.decode(data)
    }
}
