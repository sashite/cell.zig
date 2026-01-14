# sashite_cell.zig

[![Zig](https://img.shields.io/badge/Zig-0.15.0-f7a41d?logo=zig)](https://ziglang.org/)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

> Idiomatic Zig implementation of the [CELL Specification v1.0.0](https://sashite.dev/specs/cell/1.0.0/).

## Implementation Constraints

This library implements a constrained subset of CELL, enabling zero-allocation, stack-only operations:

| Constraint | Value |
|------------|-------|
| Maximum dimensions | 3 |
| Maximum index value | 255 |
| Maximum string length | 7 characters |

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

// Runtime parsing
const coord = try cell.parse("e4");
// coord.indices = { 4, 3, 0 }
// coord.dimensions = 2

// Access as slice
const indices = coord.slice(); // []const u8{ 4, 3 }

// Comptime parsing
const static_coord = comptime cell.parseComptime("a1A");
// static_coord.indices = { 0, 0, 0 }
// static_coord.dimensions = 3
```

### Formatting (Coordinate → String)

Convert a `Coordinate` back to a CELL string.

```zig
// From Coordinate struct
const coord = cell.Coordinate.init(.{ 4, 3 });
const formatted = cell.format(coord);
// formatted.slice() = "e4"

// Writer (flexible output)
var buf: [cell.max_string_len]u8 = undefined;
var stream = std.io.fixedBufferStream(&buf);
try cell.formatWrite(stream.writer(), coord);
// stream.getWritten() = "e4"
```

### Validation

```zig
// Check validity (returns bool)
if (cell.isValid("a1")) {
    // ...
}

// Get detailed error
cell.validate("a0") catch |err| switch (err) {
    error.LeadingZero => std.debug.print("Zero not allowed\n", .{}),
    else => {},
};

// Compile-time validation
comptime {
    std.debug.assert(cell.isValid("a1"));
    std.debug.assert(!cell.isValid("a0"));
}
```

## API Reference

```zig
// Constants
pub const max_dimensions: u8 = 3;
pub const max_index_value: u8 = 255;
pub const max_string_len: u8 = 7;

// Coordinate type (0-indexed indices)
pub const Coordinate = struct {
    indices: [max_dimensions]u8,  // Unused positions are 0
    dimensions: u2,               // Valid range: 1, 2, 3

    /// Creates a Coordinate from a tuple of u8 values.
    /// Example: Coordinate.init(.{ 4, 3 }) → dimensions=2, indices={4,3,0}
    pub fn init(values: anytype) Coordinate;

    /// Returns indices[0..dimensions].
    pub fn slice(self: *const Coordinate) []const u8;
};

// Formatted string type
pub const FormattedCoordinate = struct {
    buf: [max_string_len]u8,  // Unused positions are undefined
    len: u3,                  // Valid range: 1–7

    /// Returns buf[0..len].
    pub fn slice(self: *const FormattedCoordinate) []const u8;
};

// Parsing
/// Parses a CELL string into a Coordinate.
pub fn parse(s: []const u8) ParseError!Coordinate

/// Parses a CELL string at compile time. Triggers @compileError if invalid.
pub fn parseComptime(comptime s: []const u8) Coordinate

// Formatting
/// Formats a Coordinate into a CELL string.
pub fn format(coord: Coordinate) FormattedCoordinate

/// Writes a formatted Coordinate to any writer. Returns writer errors only.
pub fn formatWrite(writer: anytype, coord: Coordinate) @TypeOf(writer).Error!void

// Validation
/// Validates a CELL string and returns the specific error if invalid.
pub fn validate(s: []const u8) ParseError!void

/// Returns true if the string is a valid CELL coordinate.
pub fn isValid(s: []const u8) bool

// Errors
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

This implementation follows Zig idioms:

- **Zero allocation**: All operations use stack memory only.
- **Bounded types**: `u8` indices and `u2` dimension count prevent overflow.
- **Comptime evaluation**: `parseComptime` validates at compile time.
- **Explicit errors**: Detailed `ParseError` variants for precise diagnostics.
- **No hidden control flow**: Errors are explicit via error unions.
- **No dependencies**: Pure Zig with zero external dependencies.

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [CELL Specification](https://sashite.dev/specs/cell/1.0.0/) — Official specification
- [CELL Examples](https://sashite.dev/specs/cell/1.0.0/examples/) — Usage examples

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
