# Swift INI

A Swift library for decoding and encoding INI configuration files with full support for sections, comments, quoted values, and various INI formats.

## Features

- ✅ **Simple API**: Easy-to-use encoder and decoder
- ✅ **Global and Named Sections**: Support for properties before any section and in named sections
- ✅ **Comments**: Support for both `;` and `#` comment styles
- ✅ **Quoted Values**: Handle quoted strings with escape sequences
- ✅ **Flexible Separators**: Support for both `=` and `:` as key-value separators
- ✅ **Custom Options**: Configurable encoding and decoding behavior
- ✅ **Type Safety**: Strongly typed with Swift's type system
- ✅ **Thread Safe**: All types are `Sendable`
- ✅ **Round-trip**: Encode and decode without losing data
- ✅ **Error Handling**: Detailed error messages for invalid INI files

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/swift-ini.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["INI"]
)
```

## Quick Start

### Decoding an INI File

```swift
import INI

let iniString = """
app_name = My Application
version = 1.0.0

[database]
host = localhost
port = 5432
username = admin
"""

let ini = try INI(string: iniString)

// Access global properties
print(ini.global["app_name"]) // "My Application"

// Access section properties
print(ini["database", "host"]) // "localhost"
print(ini["database", "port"]) // "5432"
```

### Encoding an INI File

```swift
import INI

var ini = INI()

// Set global properties
ini.global["app_name"] = "My Application"
ini.global["version"] = "1.0.0"

// Set section properties
ini["database", "host"] = "localhost"
ini["database", "port"] = "5432"

// Encode to string
let encoded = ini.encode()
print(encoded)
```

## Detailed Usage

### Working with Sections

```swift
var ini = INI()

// Access or create sections
ini["server", "host"] = "example.com"
ini["server", "port"] = "8080"

// Get all section names
print(ini.sectionNames) // ["server"]

// Iterate over sections
for (name, section) in ini.allSections {
    print("Section: \(name)")
    for (key, value) in section.items {
        print("  \(key) = \(value)")
    }
}

// Check if a section exists
if let section = ini["server"] {
    print("Server section has \(section.count) properties")
}
```

### Dictionary Literal Initialization

```swift
let ini: INI = [
    "": ["global_key": "global_value"],
    "section1": ["key1": "value1", "key2": "value2"],
    "section2": ["key3": "value3"]
]
```

### Comments

Comments are automatically ignored during decoding:

```swift
let iniString = """
; This is a comment
key1 = value1  ; inline comment
# Another comment style
key2 = value2  # inline comment
"""

let ini = try INI(string: iniString)
// Comments are stripped, only key-value pairs remain
```

### Quoted Values

Values can be quoted to preserve special characters:

```swift
let iniString = """
message = "Hello; World"
path = "C:\\Users\\Name\\Documents"
multiline = "Line 1\\nLine 2"
"""

let ini = try INI(string: iniString)
print(ini.global["message"])    // "Hello; World"
print(ini.global["path"])       // "C:\Users\Name\Documents"
print(ini.global["multiline"])  // "Line 1\nLine 2"
```

### Escape Sequences

Supported escape sequences in quoted values:
- `\\n` - Newline
- `\\r` - Carriage return
- `\\t` - Tab
- `\\\\` - Backslash
- `\\"` - Double quote
- `\\'` - Single quote

## Decoding Options

Customize the decoder behavior:

```swift
var options = INIDecoder.Options()
options.commentCharacters = [";", "#"]
options.trimWhitespace = true
options.allowDuplicateKeys = false  // Throw error on duplicates
options.parseQuotedValues = true
options.allowKeysWithoutValues = true
options.separatorCharacters = ["=", ":"]

let decoder = INIDecoder(options: options)
let ini = try decoder.decode(iniString)
```

### Decoding Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `commentCharacters` | `Set<Character>` | `[";", "#"]` | Characters that indicate comment lines |
| `trimWhitespace` | `Bool` | `true` | Trim whitespace from keys and values |
| `allowDuplicateKeys` | `Bool` | `true` | Allow duplicate keys (last one wins) |
| `parseQuotedValues` | `Bool` | `true` | Parse quoted values and escape sequences |
| `allowKeysWithoutValues` | `Bool` | `true` | Allow keys without values (empty string) |
| `separatorCharacters` | `Set<Character>` | `["=", ":"]` | Key-value separator characters |

## Encoding Options

Customize the encoder output:

```swift
var options = INIEncoder.Options()
options.separator = " = "
options.addBlankLineBetweenSections = true
options.sortSections = true
options.sortKeys = true
options.quoteSpecialValues = true
options.lineEnding = .lf  // or .crlf for Windows

let encoder = INIEncoder(options: options)
let encoded = encoder.encode(ini)
```

### Encoding Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `separator` | `String` | `" = "` | Separator between key and value |
| `addBlankLineBetweenSections` | `Bool` | `true` | Add blank lines between sections |
| `addBlankLineAfterGlobal` | `Bool` | `true` | Add blank line after global section |
| `sortSections` | `Bool` | `true` | Sort section names alphabetically |
| `sortKeys` | `Bool` | `true` | Sort keys within sections |
| `quoteSpecialValues` | `Bool` | `true` | Quote values with special characters |
| `specialCharacters` | `Set<Character>` | `[";", "#", "=", ":", "[", "]"]` | Characters that trigger quoting |
| `lineEnding` | `LineEnding` | `.lf` | Line ending style (`.lf`, `.crlf`, `.cr`) |
| `includeEmptyGlobalSection` | `Bool` | `false` | Include global section if empty |
| `includeEmptySections` | `Bool` | `false` | Include empty sections |

## Error Handling

The library provides detailed error messages:

```swift
do {
    let ini = try INI(string: invalidINIString)
} catch INIDecoder.DecodingError.invalidSection(let line, let content) {
    print("Invalid section at line \(line): \(content)")
} catch INIDecoder.DecodingError.duplicateKey(let section, let key, let line) {
    print("Duplicate key '\(key)' in section '\(section)' at line \(line)")
} catch INIDecoder.DecodingError.invalidKeyValuePair(let line, let content) {
    print("Invalid key-value pair at line \(line): \(content)")
} catch {
    print("Error: \(error)")
}
```

## Real-World Examples

### Application Configuration

```swift
let config = """
[app]
name = My Application
version = 1.2.3
environment = production

[database]
host = db.example.com
port = 5432
name = myapp_db
pool_size = 10

[cache]
enabled = true
ttl = 3600
"""

let ini = try INI(string: config)

let appName = ini["app", "name"]
let dbHost = ini["database", "host"]
let cacheEnabled = ini["cache", "enabled"] == "true"
```

### Git Config Style

```swift
let gitConfig = """
[core]
repositoryformatversion = 0
filemode = true

[remote "origin"]
url = https://github.com/user/repo.git
fetch = +refs/heads/*:refs/remotes/origin/*

[branch "main"]
remote = origin
merge = refs/heads/main
"""

let ini = try INI(string: gitConfig)
let url = ini["remote \"origin\"", "url"]
```

### Windows INI File

```swift
var options = INIEncoder.Options()
options.lineEnding = .crlf
options.separator = "="

var ini = INI()
ini["Settings", "Language"] = "English"
ini["Settings", "Theme"] = "Dark"

let windowsINI = ini.encode(options: options)
```

## Advanced Usage

### Modifying Sections

```swift
var ini = try INI(string: configString)

// Modify existing values
ini["database", "host"] = "newhost.example.com"

// Add new properties
ini["cache", "enabled"] = "true"
ini["cache", "ttl"] = "3600"

// Remove properties by setting to nil
ini["database", "old_setting"] = nil

// Save back
let updated = ini.encode()
```

### Working with Data

```swift
// Decode from Data
let data = try Data(contentsOf: url)
let ini = try INI(data: data)

// Encode to Data
let encodedData = ini.encodeData()
try encodedData.write(to: url)
```

### Type Conversions

```swift
let ini = try INI(string: configString)

// Convert string values to other types
if let portString = ini["server", "port"],
   let port = Int(portString) {
    print("Port: \(port)")
}

if let enabled = ini["cache", "enabled"] {
    let isEnabled = enabled.lowercased() == "true"
    print("Cache enabled: \(isEnabled)")
}
```

## Performance Considerations

- The library uses efficient string parsing with minimal allocations
- Sections are stored in dictionaries for O(1) access
- Large files (10,000+ lines) are handled efficiently
- Consider streaming for extremely large files (100MB+)

## Thread Safety

All types in this library are `Sendable` and can be safely used across threads:

```swift
let ini = try INI(string: configString)

Task {
    let value = ini["section", "key"]
    // Safe to read from multiple threads
}
```

Note: Modifying an `INI` instance from multiple threads requires external synchronization (like using an actor).

## Compatibility

- **Swift**: 5.9+
- **Platforms**: iOS 18+, macOS 15+
- **Dependencies**: None (Foundation only)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This library is released under the MIT License. See LICENSE for details.

## Acknowledgments

INI file format is widely used in configuration files. This library aims to provide a modern, Swift-native way to work with them.