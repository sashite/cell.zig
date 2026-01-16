//! Security tests for CELL coordinate parsing.
//!
//! Verifies that malicious or malformed inputs are properly rejected.

const std = @import("std");
const cell = @import("../cell.zig");

const isValid = cell.isValid;
const parse = cell.parse;
const ParseError = cell.ParseError;

// ============================================================================
// Null Byte Injection
// ============================================================================

test "security: null byte rejected" {
    try std.testing.expect(!isValid("a\x00"));
    try std.testing.expect(!isValid("\x00a"));
    try std.testing.expect(!isValid("a\x001"));
    try std.testing.expect(!isValid("a1\x00A"));
}

// ============================================================================
// Control Characters
// ============================================================================

test "security: newline rejected" {
    try std.testing.expect(!isValid("a\n"));
    try std.testing.expect(!isValid("a\n1"));
    try std.testing.expect(!isValid("\na1"));
    try std.testing.expect(!isValid("a1\nA"));
}

test "security: carriage return rejected" {
    try std.testing.expect(!isValid("a\r"));
    try std.testing.expect(!isValid("a\r1"));
    try std.testing.expect(!isValid("a\r\n1"));
}

test "security: tab rejected" {
    try std.testing.expect(!isValid("a\t"));
    try std.testing.expect(!isValid("a\t1"));
    try std.testing.expect(!isValid("\ta1"));
}

test "security: other control characters rejected" {
    try std.testing.expect(!isValid("a\x01")); // SOH
    try std.testing.expect(!isValid("a\x02")); // STX
    try std.testing.expect(!isValid("a\x1b")); // ESC
    try std.testing.expect(!isValid("a\x7f")); // DEL
    try std.testing.expect(!isValid("a\x0b")); // vertical tab
    try std.testing.expect(!isValid("a\x0c")); // form feed
    try std.testing.expect(!isValid("a\x08")); // backspace
}

// ============================================================================
// High-Bit / Extended ASCII Characters
// ============================================================================

test "security: high-bit characters rejected" {
    try std.testing.expect(!isValid("a\x80")); // First high-bit char
    try std.testing.expect(!isValid("a\xff")); // Last byte value
    try std.testing.expect(!isValid("\x80a"));
    try std.testing.expect(!isValid("a\xe4")); // Common in UTF-8 sequences
}

// ============================================================================
// Unicode Lookalikes (as UTF-8 bytes)
// ============================================================================

test "security: cyrillic lookalikes rejected (UTF-8 encoded)" {
    // Cyrillic small letter A (U+0430) = 0xD0 0xB0 in UTF-8
    // Looks like Latin 'a' but is different bytes
    try std.testing.expect(!isValid("\xd0\xb0")); // Cyrillic 'а'
    try std.testing.expect(!isValid("\xd0\xb5")); // Cyrillic 'е' (looks like 'e')
    try std.testing.expect(!isValid("\xd0\xbe")); // Cyrillic 'о' (looks like 'o')
}

test "security: greek lookalikes rejected (UTF-8 encoded)" {
    // Greek small letter alpha (U+03B1) = 0xCE 0xB1 in UTF-8
    try std.testing.expect(!isValid("\xce\xb1")); // Greek 'α'
}

test "security: full-width characters rejected (UTF-8 encoded)" {
    // Full-width 'a' (U+FF41) = 0xEF 0xBD 0x81 in UTF-8
    try std.testing.expect(!isValid("\xef\xbd\x81")); // Full-width 'a'
    try std.testing.expect(!isValid("\xef\xbc\x91")); // Full-width '1'
    try std.testing.expect(!isValid("\xef\xbc\xa1")); // Full-width 'A'
}

// ============================================================================
// Zero-Width Characters (as UTF-8 bytes)
// ============================================================================

test "security: zero-width characters rejected (UTF-8 encoded)" {
    // Zero-width space (U+200B) = 0xE2 0x80 0x8B in UTF-8
    try std.testing.expect(!isValid("a\xe2\x80\x8b1")); // zero-width space
    try std.testing.expect(!isValid("a\xe2\x80\x8c1")); // zero-width non-joiner (U+200C)
    try std.testing.expect(!isValid("a\xe2\x80\x8d1")); // zero-width joiner (U+200D)
    try std.testing.expect(!isValid("a\xef\xbb\xbf1")); // BOM (U+FEFF)
}

// ============================================================================
// Combining Characters (as UTF-8 bytes)
// ============================================================================

test "security: combining characters rejected (UTF-8 encoded)" {
    // Combining acute accent (U+0301) = 0xCC 0x81 in UTF-8
    try std.testing.expect(!isValid("a\xcc\x81")); // 'a' + combining acute
    try std.testing.expect(!isValid("e\xcc\x88")); // 'e' + combining diaeresis (U+0308)
}

// ============================================================================
// Whitespace Variants
// ============================================================================

test "security: space rejected" {
    try std.testing.expect(!isValid(" a1"));
    try std.testing.expect(!isValid("a1 "));
    try std.testing.expect(!isValid("a 1"));
    try std.testing.expect(!isValid("a1 A"));
}

test "security: non-breaking space rejected (UTF-8 encoded)" {
    // Non-breaking space (U+00A0) = 0xC2 0xA0 in UTF-8
    try std.testing.expect(!isValid("a\xc2\xa01"));
}

// ============================================================================
// Maximum Valid Input
// ============================================================================

test "security: maximum valid input accepted" {
    // "iv256IV" is the maximum valid coordinate (255, 255, 255)
    const coord = try parse("iv256IV");
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 255, 255, 255 }, coord.slice());
}

test "security: just over maximum length rejected" {
    try std.testing.expect(!isValid("iv256IVa")); // 8 chars
    try std.testing.expect(!isValid("iv256IVaa")); // 9 chars
    try std.testing.expect(!isValid("aaaaaaaa")); // 8 lowercase
}

test "security: just over maximum index rejected" {
    try std.testing.expect(!isValid("iw")); // 256 in lowercase
    try std.testing.expect(!isValid("a257")); // 257 in digits
    try std.testing.expect(!isValid("a1IW")); // 256 in uppercase
}

// ============================================================================
// Mixed Valid and Invalid
// ============================================================================

test "security: invalid character anywhere is rejected" {
    try std.testing.expect(!isValid("!a1A")); // invalid at start
    try std.testing.expect(!isValid("a!1A")); // invalid after lowercase
    try std.testing.expect(!isValid("a1!A")); // invalid after digit
    try std.testing.expect(!isValid("a1A!")); // invalid at end
}

test "security: null byte hidden in valid-looking input" {
    try std.testing.expect(!isValid("e\x004"));
    try std.testing.expect(!isValid("e4\x00"));
}

// ============================================================================
// Parser Statelessness
// ============================================================================

test "security: repeated parsing is stateless" {
    // Parse the same input many times to ensure no state leakage
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const coord = try parse("e4");
        try std.testing.expectEqual(@as(u8, 4), coord.indices[0]);
        try std.testing.expectEqual(@as(u8, 3), coord.indices[1]);
    }
}

// ============================================================================
// Empty Segments
// ============================================================================

test "security: empty and minimal invalid inputs" {
    try std.testing.expect(!isValid("")); // empty
    try std.testing.expect(!isValid("1")); // digit only
    try std.testing.expect(!isValid("A")); // uppercase only
    try std.testing.expect(!isValid("1a")); // wrong order
    try std.testing.expect(!isValid("A1")); // wrong order
}
