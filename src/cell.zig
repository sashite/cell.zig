//! CELL (Coordinate Encoding for Layered Locations)
//!
//! A standardized format for representing coordinates on multi-dimensional
//! game boards using a cyclical ASCII character system.
//!
//! This implementation supports up to 3 dimensions with index values 0–255.
//!
//! Specification: https://sashite.dev/specs/cell/1.0.0/

const std = @import("std");

const parse_module = @import("parse.zig");
const format_module = @import("format.zig");

// ============================================================================
// Constants
// ============================================================================

/// Maximum number of dimensions supported.
pub const max_dimensions: u8 = 3;

/// Maximum value for any single index (0-indexed).
pub const max_index_value: u8 = 255;

/// Maximum length of a formatted CELL string.
/// Breakdown: 2 (lowercase) + 3 (digit) + 2 (uppercase) = 7
pub const max_string_len: u8 = 7;

// ============================================================================
// Error Types
// ============================================================================

/// Errors that can occur during parsing or validation.
pub const ParseError = error{
    /// String length is 0.
    EmptyInput,
    /// String exceeds 7 characters.
    InputTooLong,
    /// Must start with lowercase letter.
    InvalidStart,
    /// Character violates the cyclic sequence.
    UnexpectedCharacter,
    /// Numeric part starts with '0'.
    LeadingZero,
    /// More than 3 dimensions.
    TooManyDimensions,
    /// Decoded value exceeds 255.
    IndexOutOfRange,
};

// ============================================================================
// Coordinate Type
// ============================================================================

/// A parsed CELL coordinate with 0-indexed indices.
pub const Coordinate = struct {
    /// Index values for each dimension. Unused positions are 0.
    indices: [max_dimensions]u8,
    /// Number of dimensions (valid range: 1, 2, 3).
    dimensions: u2,

    /// Creates a Coordinate from a tuple of u8 values.
    ///
    /// Example:
    /// ```
    /// const coord = Coordinate.init(.{ 4, 3 });
    /// // coord.dimensions = 2
    /// // coord.indices = { 4, 3, 0 }
    /// ```
    pub fn init(values: anytype) Coordinate {
        const T = @TypeOf(values);
        const len = @typeInfo(T).@"struct".fields.len;

        if (len == 0 or len > max_dimensions) {
            @compileError("Coordinate.init requires 1 to 3 values");
        }

        var result = Coordinate{
            .indices = .{ 0, 0, 0 },
            .dimensions = @intCast(len),
        };

        inline for (0..len) |i| {
            result.indices[i] = values[i];
        }

        return result;
    }

    /// Returns indices[0..dimensions].
    pub fn slice(self: *const Coordinate) []const u8 {
        return self.indices[0..self.dimensions];
    }
};

// ============================================================================
// FormattedCoordinate Type
// ============================================================================

/// A formatted CELL string stored in a fixed-size buffer.
pub const FormattedCoordinate = struct {
    /// Buffer containing the formatted string. Unused positions are undefined.
    buf: [max_string_len]u8,
    /// Length of the formatted string (valid range: 1–7).
    len: u3,

    /// Returns buf[0..len].
    pub fn slice(self: *const FormattedCoordinate) []const u8 {
        return self.buf[0..self.len];
    }
};

// ============================================================================
// Public API - Parsing
// ============================================================================

/// Parses a CELL string into a Coordinate.
///
/// Returns a ParseError if the input is invalid.
///
/// Example:
/// ```
/// const coord = try parse("e4");
/// // coord.indices = { 4, 3, 0 }
/// // coord.dimensions = 2
/// ```
pub const parse = parse_module.parse;

/// Parses a CELL string at compile time.
///
/// Triggers @compileError if the input is invalid.
///
/// Example:
/// ```
/// const coord = comptime parseComptime("a1A");
/// // coord.indices = { 0, 0, 0 }
/// // coord.dimensions = 3
/// ```
pub const parseComptime = parse_module.parseComptime;

// ============================================================================
// Public API - Formatting
// ============================================================================

/// Formats a Coordinate into a CELL string.
///
/// Example:
/// ```
/// const coord = Coordinate.init(.{ 4, 3 });
/// const formatted = format(coord);
/// // formatted.slice() returns "e4"
/// ```
pub const format = format_module.format;

/// Writes a formatted Coordinate to any writer.
///
/// Returns only writer errors.
///
/// Example:
/// ```
/// try formatWrite(writer, coord);
/// ```
pub const formatWrite = format_module.formatWrite;

// ============================================================================
// Public API - Validation
// ============================================================================

/// Validates a CELL string and returns the specific error if invalid.
///
/// Example:
/// ```
/// validate("a0") catch |err| switch (err) {
///     error.LeadingZero => // handle error,
///     else => {},
/// };
/// ```
pub const validate = parse_module.validate;

/// Returns true if the string is a valid CELL coordinate.
///
/// Example:
/// ```
/// if (isValid("a1")) {
///     // valid coordinate
/// }
/// ```
pub const isValid = parse_module.isValid;

// ============================================================================
// Tests
// ============================================================================

test {
    // Run tests from all submodules
    std.testing.refAllDecls(@This());
    _ = @import("tests/validate_tests.zig");
    _ = @import("tests/parse_tests.zig");
    _ = @import("tests/format_tests.zig");
    _ = @import("tests/round_trip_tests.zig");
    _ = @import("tests/security_tests.zig");
}
