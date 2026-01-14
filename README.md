# cell.zig

[![Zig](https://img.shields.io/badge/Zig-0.15.0-f7a41d?logo=zig)](https://ziglang.org/)
[![License](https://img.shields.io/github/license/sashite/cell.zig)](https://github.com/sashite/cell.zig/blob/main/LICENSE)

> **CELL** (Coordinate Encoding for Layered Locations) implementation for Zig.

## Overview

This library implements the [CELL Specification v1.0.0](https://sashite.dev/specs/cell/1.0.0/).

### Implementation Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Max dimensions | 3 | Sufficient for 1D, 2D, 3D boards |
| Max index value | 255 | Fits in `u8`, covers 256×256×256 boards |
| Max string length | 7 | `"iv256IV"` (max for all dimensions at 255) |

These constraints enable bounded memory usage and safe parsing without allocation.

## Installation

Add `sashite_cell` as a dependency in your `build.zig.zon`:

```zig
.dependencies = .{
    .sashite_cell = .{
        .url = "https://github.com/sashite/cell.zig/archive/refs/tags/v1.0.0.tar.gz",
        .hash = "...", // Run 'zig fetch' to get the hash
    },
},
```

Then in your `build.zig`:

```zig
const sashite_cell = b.dependency("sashite_cell", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("sashite_cell", sashite_cell.module("sashite_cell"));
```

## Usage

### Parsing (String → Coordinate)

Convert a CELL string into a `Coordinate` struct.

```zig
const cell = @import("sashite_cell");

// Standard parsing (returns error)
const coord = try cell.parse("e4");
std.debug.print("{any}\n", .{coord.slice()}); // { 4, 3 }
std.debug.print("{}\n", .{coord.dimensions}); // 2

// Comptime parsing (compile error if invalid)
const c = comptime cell.parseComptime("a1A");
std.debug.print("{any}\n", .{c.slice()}); // { 0, 0, 0 }
```

### Formatting (Coordinate → String)

Convert a `Coordinate` back to a CELL string.

```zig
// From Coordinate struct
const coord = cell.Coordinate.init(.{ 4, 3 });
const formatted = cell.format(coord);
std.debug.print("{s}\n", .{formatted.slice()}); // "e4"

// Direct formatting (convenience)
const s = cell.format(cell.Coordinate.init(.{ 2, 2, 2 }));
std.debug.print("{s}\n", .{s.slice()}); // "c3C"
```

### Validation

```zig
// Boolean check
if (cell.isValid("e4")) {
    // valid coordinate
}

// Detailed error
cell.validate("a0") catch |err| {
    std.debug.print("{}\n", .{err}); // error.LeadingZero
};
```

### Accessing Coordinate Data

```zig
const coord = try cell.parse("e4");

// Get dimensions count
std.debug.print("{}\n", .{coord.dimensions}); // 2

// Get indices as slice
std.debug.print("{any}\n", .{coord.slice()}); // { 4, 3 }

// Access individual index
std.debug.print("{}\n", .{coord.indices[0]}); // 4
std.debug.print("{}\n", .{coord.indices[1]}); // 3
```

## API Reference

### Types

```zig
/// Coordinate represents a parsed CELL coordinate with up to 3 dimensions.
/// Use Coordinate.init or parse to create.
pub const Coordinate = struct {
    indices: [max_dimensions]u8,  // Unused positions are 0
    dimensions: u2,               // Valid range: 1, 2, 3

    /// Creates a Coordinate from a tuple of u8 values.
    /// Example: Coordinate.init(.{ 4, 3 }) → dimensions=2, indices={4,3,0}
    pub fn init(values: anytype) Coordinate;

    /// Returns indices[0..dimensions].
    pub fn slice(self: *const Coordinate) []const u8;
};

/// FormattedCoordinate holds the string representation of a Coordinate.
pub const FormattedCoordinate = struct {
    buf: [max_string_len]u8,  // Unused positions are undefined
    len: u3,                  // Valid range: 1–7

    /// Returns buf[0..len].
    pub fn slice(self: *const FormattedCoordinate) []const u8;
};
```

### Constants

```zig
pub const max_dimensions: u8 = 3;
pub const max_index_value: u8 = 255;
pub const max_string_len: u8 = 7;
```

### Parsing

```zig
/// Parses a CELL string into a Coordinate.
/// Returns an error if the string is not valid.
pub fn parse(s: []const u8) ParseError!Coordinate;

/// Parses a CELL string at compile time.
/// Triggers @compileError if invalid.
pub fn parseComptime(comptime s: []const u8) Coordinate;
```

### Formatting

```zig
/// Formats a Coordinate into a CELL string.
pub fn format(coord: Coordinate) FormattedCoordinate;

/// Writes a formatted Coordinate to any writer.
/// Returns writer errors only.
pub fn formatWrite(writer: anytype, coord: Coordinate) @TypeOf(writer).Error!void;
```

### Validation

```zig
/// Validates a CELL string.
/// Returns the specific error if invalid.
pub fn validate(s: []const u8) ParseError!void;

/// Reports whether s is a valid CELL coordinate.
pub fn isValid(s: []const u8) bool;
```

### Errors

```zig
pub const ParseError = error{
    EmptyInput,          // String length is 0
    InputTooLong,        // String exceeds 7 characters
    InvalidStart,        // Must start with lowercase letter
    UnexpectedCharacter, // Character violates the cyclic sequence
    LeadingZero,         // Numeric part starts with '0'
    TooManyDimensions,   // More than 3 dimensions
    IndexOutOfRange,     // Decoded value exceeds 255
};
```

## Design Principles

- **Bounded types**: `u8` indices and `u2` dimension count prevent overflow
- **Struct over slice**: `Coordinate` type enables methods and safety
- **Explicit errors**: Detailed `ParseError` variants for precise diagnostics
- **Comptime evaluation**: `parseComptime` validates at compile time
- **No allocation**: All operations use stack memory only
- **No dependencies**: Pure Zig standard library only

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [CELL Specification](https://sashite.dev/specs/cell/1.0.0/) — Official specification
- [CELL Examples](https://sashite.dev/specs/cell/1.0.0/examples/) — Usage examples

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
