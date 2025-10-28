// INI.swift
// A Swift library for decoding and encoding INI files

import Foundation

/// Represents an INI file structure with sections and key-value pairs
public struct INI: Equatable, Sendable {
    /// Storage for sections, using empty string for the global section
    private var sections: [String: Section]

    /// Represents a section in an INI file
    public struct Section: Equatable, Sendable {
        private var properties: [String: String]

        public init() {
            self.properties = [:]
        }

        public init(_ properties: [String: String]) {
            self.properties = properties
        }

        /// Get or set a value for a key
        public subscript(key: String) -> String? {
            get { properties[key] }
            set { properties[key] = newValue }
        }

        /// All keys in this section
        public var keys: Dictionary<String, String>.Keys {
            properties.keys
        }

        /// All key-value pairs in this section
        public var items: [(key: String, value: String)] {
            properties.sorted { $0.key < $1.key }
        }

        /// Check if section is empty
        public var isEmpty: Bool {
            properties.isEmpty
        }

        /// Count of properties in this section
        public var count: Int {
            properties.count
        }
    }

    /// Initialize an empty INI structure
    public init() {
        self.sections = [:]
    }

    /// Initialize with sections
    public init(_ sections: [String: Section]) {
        self.sections = sections
    }

    /// Get or set a section by name
    public subscript(section: String) -> Section? {
        get { sections[section] }
        set { sections[section] = newValue }
    }

    /// Get or set a value in a specific section
    public subscript(section: String, key: String) -> String? {
        get { sections[section]?[key] }
        set {
            if sections[section] == nil {
                sections[section] = Section()
            }
            sections[section]?[key] = newValue
        }
    }

    /// Access the global section (properties before any section header)
    public var global: Section {
        get { sections[""] ?? Section() }
        set { sections[""] = newValue }
    }

    /// All section names (excluding the global section)
    public var sectionNames: [String] {
        sections.keys.filter { !$0.isEmpty }.sorted()
    }

    /// All sections including global
    public var allSections: [(name: String, section: Section)] {
        sections.sorted { $0.key < $1.key }.map { (name: $0.key, section: $0.value) }
    }

    /// Check if INI is empty
    public var isEmpty: Bool {
        sections.isEmpty || sections.values.allSatisfy { $0.isEmpty }
    }
}

// MARK: - ExpressibleByDictionaryLiteral
extension INI: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Section)...) {
        self.sections = Dictionary(uniqueKeysWithValues: elements)
    }
}

extension INI.Section: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.properties = Dictionary(uniqueKeysWithValues: elements)
    }
}

// MARK: - CustomStringConvertible
extension INI: CustomStringConvertible {
    public var description: String {
        var result = ""

        // Global section first
        if let global = sections[""], !global.isEmpty {
            for (key, value) in global.items {
                result += "\(key) = \(value)\n"
            }
            result += "\n"
        }

        // Named sections
        for name in sectionNames {
            guard let section = sections[name] else { continue }
            result += "[\(name)]\n"
            for (key, value) in section.items {
                result += "\(key) = \(value)\n"
            }
            result += "\n"
        }

        return result
    }
}
