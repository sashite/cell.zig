//! Parsing and validation for CELL coordinates.
//!
//! Converts CELL strings (e.g., "e4", "a1A") into Coordinate structs.

const cell = @import("cell.zig");
const charset = @import("charset.zig");

const Coordinate = cell.Coordinate;
const ParseError = cell.ParseError;
const CharSet = charset.CharSet;

// ============================================================================
// Validation
// ============================================================================

/// Validates a CELL string and returns the specific error if invalid.
pub fn validate(s: []const u8) ParseError!void {
    if (s.len == 0) return ParseError.EmptyInput;
    if (s.len > cell.max_string_len) return ParseError.InputTooLong;

    // Must start with lowercase
    if (charset.classifyChar(s[0]) != .lowercase) return ParseError.InvalidStart;

    var i: usize = 0;
    var dim_index: usize = 0;

    while (i < s.len) {
        if (dim_index >= cell.max_dimensions) return ParseError.TooManyDimensions;

        const expected = charset.expectedCharSet(dim_index);
        const actual = charset.classifyChar(s[i]) orelse return ParseError.UnexpectedCharacter;

        if (actual != expected) return ParseError.UnexpectedCharacter;

        // Consume and validate the entire segment
        const start = i;
        switch (expected) {
            .lowercase => {
                while (i < s.len and charset.classifyChar(s[i]) == .lowercase) : (i += 1) {}
                // Validate index range
                if (decodeLowercase(s[start..i])) |_| {} else |_| return ParseError.IndexOutOfRange;
            },
            .digit => {
                // Check for leading zero
                if (s[i] == '0') return ParseError.LeadingZero;
                while (i < s.len and charset.classifyChar(s[i]) == .digit) : (i += 1) {}
                // Validate index range
                if (decodeNumeric(s[start..i])) |_| {} else |_| return ParseError.IndexOutOfRange;
            },
            .uppercase => {
                while (i < s.len and charset.classifyChar(s[i]) == .uppercase) : (i += 1) {}
                // Validate index range
                if (decodeUppercase(s[start..i])) |_| {} else |_| return ParseError.IndexOutOfRange;
            },
        }

        dim_index += 1;
    }
}

/// Returns true if the string is a valid CELL coordinate.
pub fn isValid(s: []const u8) bool {
    validate(s) catch return false;
    return true;
}

// ============================================================================
// Parsing
// ============================================================================

/// Parses a CELL string into a Coordinate.
pub fn parse(s: []const u8) ParseError!Coordinate {
    try validate(s);

    var result = Coordinate{
        .indices = .{ 0, 0, 0 },
        .dimensions = 0,
    };

    var i: usize = 0;
    var dim_index: usize = 0;

    while (i < s.len and dim_index < cell.max_dimensions) {
        const expected = charset.expectedCharSet(dim_index);
        const start = i;

        switch (expected) {
            .lowercase => {
                while (i < s.len and charset.classifyChar(s[i]) == .lowercase) : (i += 1) {}
                result.indices[dim_index] = try decodeLowercase(s[start..i]);
            },
            .digit => {
                while (i < s.len and charset.classifyChar(s[i]) == .digit) : (i += 1) {}
                result.indices[dim_index] = try decodeNumeric(s[start..i]);
            },
            .uppercase => {
                while (i < s.len and charset.classifyChar(s[i]) == .uppercase) : (i += 1) {}
                result.indices[dim_index] = try decodeUppercase(s[start..i]);
            },
        }

        dim_index += 1;
    }

    result.dimensions = @intCast(dim_index);
    return result;
}

/// Parses a CELL string at compile time. Triggers @compileError if invalid.
pub fn parseComptime(comptime s: []const u8) Coordinate {
    comptime {
        return parse(s) catch |err| @compileError("Invalid CELL coordinate: " ++ @errorName(err));
    }
}

// ============================================================================
// Decoding Helpers
// ============================================================================

/// Decodes a bijective base-26 lowercase string to a 0-indexed u8 value.
/// "a" -> 0, "z" -> 25, "aa" -> 26, "iv" -> 255
fn decodeLowercase(s: []const u8) ParseError!u8 {
    var value: usize = 0;
    for (s) |c| {
        value = value * 26 + (c - 'a' + 1);
    }
    value -= 1;

    if (value > cell.max_index_value) return ParseError.IndexOutOfRange;
    return @intCast(value);
}

/// Decodes a bijective base-26 uppercase string to a 0-indexed u8 value.
/// "A" -> 0, "Z" -> 25, "AA" -> 26, "IV" -> 255
fn decodeUppercase(s: []const u8) ParseError!u8 {
    var value: usize = 0;
    for (s) |c| {
        value = value * 26 + (c - 'A' + 1);
    }
    value -= 1;

    if (value > cell.max_index_value) return ParseError.IndexOutOfRange;
    return @intCast(value);
}

/// Decodes a decimal string to a 0-indexed u8 value.
/// "1" -> 0, "4" -> 3, "256" -> 255
fn decodeNumeric(s: []const u8) ParseError!u8 {
    var value: usize = 0;
    for (s) |c| {
        value = value * 10 + (c - '0');
    }
    // CELL uses 1-indexed numbers, convert to 0-indexed
    value -= 1;

    if (value > cell.max_index_value) return ParseError.IndexOutOfRange;
    return @intCast(value);
}
