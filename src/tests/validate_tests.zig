//! Tests for CELL coordinate validation.

const std = @import("std");
const cell = @import("../cell.zig");

const ParseError = cell.ParseError;
const validate = cell.validate;
const isValid = cell.isValid;

// ============================================================================
// isValid - Valid Coordinates
// ============================================================================

test "isValid: 1D coordinates" {
    try std.testing.expect(isValid("a"));
    try std.testing.expect(isValid("z"));
    try std.testing.expect(isValid("aa"));
    try std.testing.expect(isValid("iv")); // 255
}

test "isValid: 2D coordinates" {
    try std.testing.expect(isValid("a1"));
    try std.testing.expect(isValid("e4"));
    try std.testing.expect(isValid("h8"));
    try std.testing.expect(isValid("z9"));
    try std.testing.expect(isValid("a256")); // max numeric
    try std.testing.expect(isValid("iv256")); // max both
}

test "isValid: 3D coordinates" {
    try std.testing.expect(isValid("a1A"));
    try std.testing.expect(isValid("e4B"));
    try std.testing.expect(isValid("c3C"));
    try std.testing.expect(isValid("iv256IV")); // all at max
}

// ============================================================================
// isValid - Invalid Coordinates
// ============================================================================

test "isValid: empty string" {
    try std.testing.expect(!isValid(""));
}

test "isValid: wrong start character" {
    try std.testing.expect(!isValid("1"));
    try std.testing.expect(!isValid("A"));
    try std.testing.expect(!isValid("1a"));
    try std.testing.expect(!isValid("A1"));
}

test "isValid: leading zero" {
    try std.testing.expect(!isValid("a0"));
    try std.testing.expect(!isValid("a01"));
    try std.testing.expect(!isValid("a00"));
}

test "isValid: wrong sequence" {
    try std.testing.expect(!isValid("aA")); // missing numeric
    try std.testing.expect(!isValid("a1a")); // missing uppercase
    try std.testing.expect(!isValid("a1A1")); // numeric after uppercase without lowercase
}

test "isValid: invalid characters" {
    try std.testing.expect(!isValid("a1!"));
    try std.testing.expect(!isValid("a-1"));
    try std.testing.expect(!isValid("a 1"));
    try std.testing.expect(!isValid("a1\n"));
}

test "isValid: input too long" {
    try std.testing.expect(!isValid("a1A1A1A1")); // 8 chars, max is 7
    try std.testing.expect(!isValid("abcdefgh")); // 8 chars
}

test "isValid: index out of range" {
    try std.testing.expect(!isValid("iw")); // 256 in lowercase (> 255)
    try std.testing.expect(!isValid("a257")); // 256 in numeric (> 255)
    try std.testing.expect(!isValid("a1IW")); // 256 in uppercase (> 255)
}

// ============================================================================
// validate - Detailed Errors
// ============================================================================

test "validate: EmptyInput" {
    try std.testing.expectError(ParseError.EmptyInput, validate(""));
}

test "validate: InputTooLong" {
    try std.testing.expectError(ParseError.InputTooLong, validate("a1A1A1A1"));
    try std.testing.expectError(ParseError.InputTooLong, validate("abcdefgh"));
}

test "validate: InvalidStart" {
    try std.testing.expectError(ParseError.InvalidStart, validate("1a"));
    try std.testing.expectError(ParseError.InvalidStart, validate("A1"));
    try std.testing.expectError(ParseError.InvalidStart, validate("1"));
    try std.testing.expectError(ParseError.InvalidStart, validate("A"));
}

test "validate: UnexpectedCharacter" {
    try std.testing.expectError(ParseError.UnexpectedCharacter, validate("aA"));
    try std.testing.expectError(ParseError.UnexpectedCharacter, validate("a1a"));
    try std.testing.expectError(ParseError.UnexpectedCharacter, validate("a!"));
    try std.testing.expectError(ParseError.UnexpectedCharacter, validate("a1!"));
}

test "validate: LeadingZero" {
    try std.testing.expectError(ParseError.LeadingZero, validate("a0"));
    try std.testing.expectError(ParseError.LeadingZero, validate("a01"));
    try std.testing.expectError(ParseError.LeadingZero, validate("a00"));
}

test "validate: IndexOutOfRange" {
    try std.testing.expectError(ParseError.IndexOutOfRange, validate("iw")); // 256
    try std.testing.expectError(ParseError.IndexOutOfRange, validate("a257"));
    try std.testing.expectError(ParseError.IndexOutOfRange, validate("a1IW"));
}

test "validate: TooManyDimensions" {
    try std.testing.expectError(ParseError.TooManyDimensions, validate("a1Aa"));
    try std.testing.expectError(ParseError.TooManyDimensions, validate("a1A!")); // 4th dimension attempt
}

// ============================================================================
// validate - Success Cases
// ============================================================================

test "validate: valid coordinates return void" {
    try validate("a1");
    try validate("e4");
    try validate("a1A");
    try validate("iv256IV");
}

// ============================================================================
// Edge Cases
// ============================================================================

test "edge case: boundary values" {
    // Minimum values
    try std.testing.expect(isValid("a")); // 0 in 1D
    try std.testing.expect(isValid("a1")); // 0,0 in 2D
    try std.testing.expect(isValid("a1A")); // 0,0,0 in 3D

    // Maximum values
    try std.testing.expect(isValid("iv")); // 255 in 1D
    try std.testing.expect(isValid("iv256")); // 255,255 in 2D
    try std.testing.expect(isValid("iv256IV")); // 255,255,255 in 3D

    // Just below maximum
    try std.testing.expect(isValid("iu")); // 254 in lowercase
    try std.testing.expect(isValid("a255")); // 254 in numeric
    try std.testing.expect(isValid("a1IU")); // 254 in uppercase
}

test "edge case: maximum string length" {
    // Exactly 7 characters (maximum)
    try std.testing.expect(isValid("iv256IV")); // 7 chars, valid

    // 8 characters (too long)
    try std.testing.expect(!isValid("iv256IVa")); // 8 chars, invalid
}
