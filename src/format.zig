//! Formatting for CELL coordinates.
//!
//! Converts Coordinate structs into CELL strings (e.g., "e4", "a1A").

const cell = @import("cell.zig");
const charset = @import("charset.zig");

const Coordinate = cell.Coordinate;
const FormattedCoordinate = cell.FormattedCoordinate;

// ============================================================================
// Formatting
// ============================================================================

/// Formats a Coordinate into a CELL string.
pub fn format(coord: Coordinate) FormattedCoordinate {
    var result = FormattedCoordinate{
        .buf = undefined,
        .len = 0,
    };

    var pos: usize = 0;

    for (0..coord.dimensions) |dim_index| {
        const value = coord.indices[dim_index];

        switch (charset.expectedCharSet(dim_index)) {
            .lowercase => {
                const len = encodeLowercase(result.buf[pos..], value);
                pos += len;
            },
            .digit => {
                const len = encodeNumeric(result.buf[pos..], value);
                pos += len;
            },
            .uppercase => {
                const len = encodeUppercase(result.buf[pos..], value);
                pos += len;
            },
        }
    }

    result.len = @intCast(pos);
    return result;
}

/// Writes a formatted Coordinate to any writer. Returns writer errors only.
pub fn formatWrite(writer: anytype, coord: Coordinate) @TypeOf(writer).Error!void {
    const formatted = format(coord);
    try writer.writeAll(formatted.slice());
}

// ============================================================================
// Encoding Helpers
// ============================================================================

/// Encodes a 0-indexed u8 value as bijective base-26 lowercase.
/// 0 -> "a", 25 -> "z", 26 -> "aa", 255 -> "iv"
/// Returns the number of bytes written.
fn encodeLowercase(buf: []u8, value: u8) usize {
    const len = lowercaseLength(value);
    var v: usize = @as(usize, value) + 1;
    var i: usize = len;

    while (v > 0) {
        i -= 1;
        const rem = (v - 1) % 26;
        buf[i] = @intCast('a' + rem);
        v = (v - 1) / 26;
    }

    return len;
}

/// Encodes a 0-indexed u8 value as bijective base-26 uppercase.
/// 0 -> "A", 25 -> "Z", 26 -> "AA", 255 -> "IV"
/// Returns the number of bytes written.
fn encodeUppercase(buf: []u8, value: u8) usize {
    const len = uppercaseLength(value);
    var v: usize = @as(usize, value) + 1;
    var i: usize = len;

    while (v > 0) {
        i -= 1;
        const rem = (v - 1) % 26;
        buf[i] = @intCast('A' + rem);
        v = (v - 1) / 26;
    }

    return len;
}

/// Encodes a 0-indexed u8 value as a 1-indexed decimal string.
/// 0 -> "1", 3 -> "4", 255 -> "256"
/// Returns the number of bytes written.
fn encodeNumeric(buf: []u8, value: u8) usize {
    const len = numericLength(value);
    var v: usize = @as(usize, value) + 1;
    var i: usize = len;

    while (v > 0) {
        i -= 1;
        buf[i] = @intCast('0' + (v % 10));
        v /= 10;
    }

    return len;
}

// ============================================================================
// Length Calculation Helpers
// ============================================================================

/// Returns the number of characters needed to encode a value in bijective base-26.
/// 0-25 -> 1, 26-701 -> 2 (but max value is 255, so max length is 2)
fn lowercaseLength(value: u8) usize {
    if (value < 26) return 1;
    return 2;
}

/// Returns the number of characters needed to encode a value in bijective base-26.
fn uppercaseLength(value: u8) usize {
    if (value < 26) return 1;
    return 2;
}

/// Returns the number of characters needed to encode a 1-indexed value in decimal.
/// 0-8 -> 1 ("1"-"9"), 9-98 -> 2 ("10"-"99"), 99-255 -> 3 ("100"-"256")
fn numericLength(value: u8) usize {
    const display_value = @as(usize, value) + 1; // Convert to 1-indexed
    if (display_value < 10) return 1;
    if (display_value < 100) return 2;
    return 3;
}
