//! Character set classification for CELL coordinate encoding.
//!
//! CELL uses a cyclical three-character-set system:
//! - Dimension 1, 4, 7, ... → lowercase letters (a-z)
//! - Dimension 2, 5, 8, ... → positive integers (1-256)
//! - Dimension 3, 6, 9, ... → uppercase letters (A-Z)

/// Character set categories used in CELL encoding.
pub const CharSet = enum {
    /// Lowercase letters a-z (dimensions 1, 4, 7, ...)
    lowercase,
    /// Digits 0-9 (dimensions 2, 5, 8, ...)
    digit,
    /// Uppercase letters A-Z (dimensions 3, 6, 9, ...)
    uppercase,
};

/// Classifies a character into its CharSet category.
///
/// Returns null if the character is not part of any valid CharSet.
pub fn classifyChar(c: u8) ?CharSet {
    if (c >= 'a' and c <= 'z') return .lowercase;
    if (c >= '0' and c <= '9') return .digit;
    if (c >= 'A' and c <= 'Z') return .uppercase;
    return null;
}

/// Returns the expected CharSet for a given dimension index (0-based).
///
/// Dimension 0 → lowercase
/// Dimension 1 → digit
/// Dimension 2 → uppercase
/// Dimension 3 → lowercase (cycle repeats)
pub fn expectedCharSet(dim_index: usize) CharSet {
    return switch (dim_index % 3) {
        0 => .lowercase,
        1 => .digit,
        2 => .uppercase,
        else => unreachable,
    };
}
