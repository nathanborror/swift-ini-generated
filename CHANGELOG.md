# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### Added
- Initial release of Swift INI library
- `INI` struct for representing INI file structure
- `INIDecoder` for decoding INI format strings
- `INIEncoder` for encoding INI structures to strings
- Support for global sections (properties before any section header)
- Support for named sections with `[section]` syntax
- Comment support for `;` and `#` characters
- Inline comment support
- Quoted value support with double and single quotes
- Escape sequence support (`\n`, `\r`, `\t`, `\\`, `\"`, `\'`)
- Flexible key-value separators (`=` and `:`)
- Customizable decoding options:
  - Comment characters
  - Whitespace trimming
  - Duplicate key handling
  - Quoted value parsing
  - Keys without values
  - Separator characters
- Customizable encoding options:
  - Key-value separator
  - Blank line formatting
  - Section and key sorting
  - Automatic quoting of special values
  - Line ending styles (LF, CRLF, CR)
  - Empty section handling
- Dictionary literal initialization support
- `Sendable` conformance for thread safety
- `Equatable` conformance for comparisons
- Comprehensive error handling with detailed error messages
- Data encoding/decoding support
- Round-trip encoding/decoding without data loss
- Full test coverage with 39+ unit tests
- Comprehensive documentation and examples

### Features
- ✅ Simple and intuitive API
- ✅ Type-safe with Swift's type system
- ✅ Thread-safe (all types are `Sendable`)
- ✅ Zero dependencies (Foundation only)
- ✅ Cross-platform (iOS, macOS)
- ✅ Real-world INI format compatibility
- ✅ Git config style section support
- ✅ Windows INI file support

[1.0.0]: https://github.com/yourusername/swift-ini/releases/tag/v1.0.0