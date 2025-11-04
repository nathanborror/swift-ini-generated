// INIEncoder.swift
// Encodes INI structures into INI format strings

import Foundation

/// Encodes `INI` structures into INI format strings
public struct INIEncoder {

    /// Options for encoding INI files
    public struct Options: Sendable {
        /// Separator between key and value (default: " = ")
        public var separator: String

        /// Whether to add blank lines between sections (default: true)
        public var addBlankLineBetweenSections: Bool

        /// Whether to add blank line after global section (default: true)
        public var addBlankLineAfterGlobal: Bool

        /// Whether to sort section names alphabetically (default: true)
        public var sortSections: Bool

        /// Whether to sort keys within sections alphabetically (default: true)
        public var sortKeys: Bool

        /// Whether to quote values that contain special characters (default: true)
        public var quoteSpecialValues: Bool

        /// Characters that trigger quoting (default: [";", "=", ":", "[", "]"])
        public var specialCharacters: Set<Character>

        /// Line ending style (default: .lf)
        public var lineEnding: LineEnding

        /// Whether to include the global section if empty (default: false)
        public var includeEmptyGlobalSection: Bool

        /// Whether to include empty sections (default: false)
        public var includeEmptySections: Bool

        public enum LineEnding: String, Sendable {
            case lf = "\n"  // Unix/Linux/macOS
            case crlf = "\r\n"  // Windows
            case cr = "\r"  // Classic Mac (rare)

            public var rawValue: String {
                switch self {
                case .lf: return "\n"
                case .crlf: return "\r\n"
                case .cr: return "\r"
                }
            }
        }

        public init(
            separator: String = " = ",
            addBlankLineBetweenSections: Bool = true,
            addBlankLineAfterGlobal: Bool = true,
            sortSections: Bool = true,
            sortKeys: Bool = true,
            quoteSpecialValues: Bool = true,
            specialCharacters: Set<Character> = [";", "=", ":", "[", "]"],
            lineEnding: LineEnding = .lf,
            includeEmptyGlobalSection: Bool = false,
            includeEmptySections: Bool = false
        ) {
            self.separator = separator
            self.addBlankLineBetweenSections = addBlankLineBetweenSections
            self.addBlankLineAfterGlobal = addBlankLineAfterGlobal
            self.sortSections = sortSections
            self.sortKeys = sortKeys
            self.quoteSpecialValues = quoteSpecialValues
            self.specialCharacters = specialCharacters
            self.lineEnding = lineEnding
            self.includeEmptyGlobalSection = includeEmptyGlobalSection
            self.includeEmptySections = includeEmptySections
        }
    }

    /// Encoding options
    public var options: Options

    /// Initialize with default options
    public init() {
        self.options = Options()
    }

    /// Initialize with custom options
    public init(options: Options) {
        self.options = options
    }

    /// Encode an INI structure into a string
    public func encode(_ ini: INI) -> String {
        var result = ""
        let nl = options.lineEnding.rawValue

        // Get sections in order
        let sections = getSectionsInOrder(ini)

        // Handle global section first
        if let globalSection = sections.first(where: { $0.name.isEmpty }) {
            if !globalSection.section.isEmpty || options.includeEmptyGlobalSection {
                result += encodeSection(globalSection.section, name: nil)

                // Add blank line after global if there are more sections
                if sections.count > 1 && options.addBlankLineAfterGlobal
                    && !globalSection.section.isEmpty
                {
                    result += nl
                }
            }
        }

        // Handle named sections
        let namedSections = sections.filter { !$0.name.isEmpty }
        for (index, item) in namedSections.enumerated() {
            if !item.section.isEmpty || options.includeEmptySections {
                result += "[\(item.name)]" + nl
                result += encodeSection(item.section, name: item.name)

                // Add blank line between sections (except after last)
                if index < namedSections.count - 1 && options.addBlankLineBetweenSections {
                    result += nl
                }
            }
        }

        return result
    }

    /// Encode an INI structure into Data
    public func encodeData(_ ini: INI) -> Data {
        let string = encode(ini)
        return string.data(using: String.Encoding.utf8) ?? Data()
    }

    // MARK: - Private Methods

    private func getSectionsInOrder(_ ini: INI) -> [(name: String, section: INI.Section)] {
        if options.sortSections {
            return ini.allSections.sorted { $0.name < $1.name }
        } else {
            return ini.allSections
        }
    }

    private func encodeSection(_ section: INI.Section, name: String?) -> String {
        let nl = options.lineEnding.rawValue
        var result = ""

        // Handle array-style sections
        if section.isArray {
            for item in section.array {
                result += "\(item)" + nl
            }
            return result
        }

        // Handle key-value sections
        let items = options.sortKeys ? section.items : Array(section.items)

        for item in items {
            // Skip properties with empty string values
            guard !item.value.isEmpty else { continue }

            let encodedValue = encodeValue(item.value)
            result += "\(item.key)\(options.separator)\(encodedValue)" + nl
        }

        return result
    }

    private func encodeValue(_ value: String) -> String {
        guard !value.isEmpty else { return value }

        // Check if value needs quoting
        if options.quoteSpecialValues && shouldQuoteValue(value) {
            return quoteValue(value)
        }

        return value
    }

    private func shouldQuoteValue(_ value: String) -> Bool {
        // Check for special characters
        if value.contains(where: { options.specialCharacters.contains($0) }) {
            return true
        }

        // Check for leading or trailing whitespace
        if value != value.trimmingCharacters(in: .whitespaces) {
            return true
        }

        // Check for newlines or other control characters
        if value.contains(where: { $0.isNewline || $0.isWhitespace && $0 != " " }) {
            return true
        }

        return false
    }

    private func quoteValue(_ value: String) -> String {
        // Escape special characters
        let escaped =
            value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")

        return "\"\(escaped)\""
    }
}

// MARK: - Convenience Methods
extension INI {
    /// Encode to string using default options
    public func encode() -> String {
        let encoder = INIEncoder()
        return encoder.encode(self)
    }

    /// Encode to string with custom options
    public func encode(options: INIEncoder.Options) -> String {
        let encoder = INIEncoder(options: options)
        return encoder.encode(self)
    }

    /// Encode to Data using default options
    public func encodeData() -> Data {
        let encoder = INIEncoder()
        return encoder.encodeData(self)
    }

    /// Encode to Data with custom options
    public func encodeData(options: INIEncoder.Options) -> Data {
        let encoder = INIEncoder(options: options)
        return encoder.encodeData(self)
    }
}
