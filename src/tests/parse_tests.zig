//! Tests for CELL coordinate parsing.

const std = @import("std");
const cell = @import("../cell.zig");

const Coordinate = cell.Coordinate;
const ParseError = cell.ParseError;
const parse = cell.parse;
const parseComptime = cell.parseComptime;

// ============================================================================
// parse - 1D Coordinates
// ============================================================================

test "parse: 1D single letter" {
    const coord = try parse("a");
    try std.testing.expectEqual(@as(u2, 1), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{0}, coord.slice());
}

test "parse: 1D letter z" {
    const coord = try parse("z");
    try std.testing.expectEqual(@as(u2, 1), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{25}, coord.slice());
}

test "parse: 1D double letter aa" {
    const coord = try parse("aa");
    try std.testing.expectEqual(@as(u2, 1), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{26}, coord.slice());
}

test "parse: 1D max value iv" {
    const coord = try parse("iv");
    try std.testing.expectEqual(@as(u2, 1), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{255}, coord.slice());
}

// ============================================================================
// parse - 2D Coordinates
// ============================================================================

test "parse: 2D basic a1" {
    const coord = try parse("a1");
    try std.testing.expectEqual(@as(u2, 2), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 0 }, coord.slice());
}

test "parse: 2D chess e4" {
    const coord = try parse("e4");
    try std.testing.expectEqual(@as(u2, 2), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 4, 3 }, coord.slice());
}

test "parse: 2D chess h8" {
    const coord = try parse("h8");
    try std.testing.expectEqual(@as(u2, 2), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 7, 7 }, coord.slice());
}

test "parse: 2D double digit a10" {
    const coord = try parse("a10");
    try std.testing.expectEqual(@as(u2, 2), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 9 }, coord.slice());
}

test "parse: 2D max values iv256" {
    const coord = try parse("iv256");
    try std.testing.expectEqual(@as(u2, 2), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 255, 255 }, coord.slice());
}

// ============================================================================
// parse - 3D Coordinates
// ============================================================================

test "parse: 3D basic a1A" {
    const coord = try parse("a1A");
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 0 }, coord.slice());
}

test "parse: 3D center b2B" {
    const coord = try parse("b2B");
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 1, 1 }, coord.slice());
}

test "parse: 3D diagonal c3C" {
    const coord = try parse("c3C");
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 2, 2, 2 }, coord.slice());
}

test "parse: 3D max values iv256IV" {
    const coord = try parse("iv256IV");
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 255, 255, 255 }, coord.slice());
}

// ============================================================================
// parse - Extended Alphabet
// ============================================================================

test "parse: extended lowercase aa" {
    const coord = try parse("aa1");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 26, 0 }, coord.slice());
}

test "parse: extended lowercase az" {
    const coord = try parse("az1");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 51, 0 }, coord.slice());
}

test "parse: extended lowercase ba" {
    const coord = try parse("ba1");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 52, 0 }, coord.slice());
}

test "parse: extended uppercase AA" {
    const coord = try parse("a1AA");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 26 }, coord.slice());
}

// ============================================================================
// parse - Error Cases
// ============================================================================

test "parse: error on empty input" {
    try std.testing.expectError(ParseError.EmptyInput, parse(""));
}

test "parse: error on invalid start" {
    try std.testing.expectError(ParseError.InvalidStart, parse("1a"));
}

test "parse: error on leading zero" {
    try std.testing.expectError(ParseError.LeadingZero, parse("a0"));
}

test "parse: error on index out of range" {
    try std.testing.expectError(ParseError.IndexOutOfRange, parse("iw")); // 256
}

// ============================================================================
// parseComptime
// ============================================================================

test "parseComptime: basic 2D" {
    const coord = comptime parseComptime("e4");
    try std.testing.expectEqual(@as(u2, 2), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 4, 3 }, coord.slice());
}

test "parseComptime: basic 3D" {
    const coord = comptime parseComptime("a1A");
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 0 }, coord.slice());
}

test "parseComptime: max values" {
    const coord = comptime parseComptime("iv256IV");
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 255, 255, 255 }, coord.slice());
}

// ============================================================================
// Coordinate.init
// ============================================================================

test "Coordinate.init: 1D" {
    const coord = Coordinate.init(.{5});
    try std.testing.expectEqual(@as(u2, 1), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{5}, coord.slice());
}

test "Coordinate.init: 2D" {
    const coord = Coordinate.init(.{ 4, 3 });
    try std.testing.expectEqual(@as(u2, 2), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 4, 3 }, coord.slice());
}

test "Coordinate.init: 3D" {
    const coord = Coordinate.init(.{ 0, 0, 0 });
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 0 }, coord.slice());
}

test "Coordinate.init: max values" {
    const coord = Coordinate.init(.{ 255, 255, 255 });
    try std.testing.expectEqual(@as(u2, 3), coord.dimensions);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 255, 255, 255 }, coord.slice());
}

// ============================================================================
// Coordinate.slice
// ============================================================================

test "Coordinate.slice: returns correct length" {
    const coord1 = Coordinate.init(.{5});
    try std.testing.expectEqual(@as(usize, 1), coord1.slice().len);

    const coord2 = Coordinate.init(.{ 4, 3 });
    try std.testing.expectEqual(@as(usize, 2), coord2.slice().len);

    const coord3 = Coordinate.init(.{ 0, 0, 0 });
    try std.testing.expectEqual(@as(usize, 3), coord3.slice().len);
}
