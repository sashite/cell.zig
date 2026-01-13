//! Tests for CELL coordinate formatting.

const std = @import("std");
const cell = @import("../cell.zig");

const Coordinate = cell.Coordinate;
const FormattedCoordinate = cell.FormattedCoordinate;
const format = cell.format;
const formatWrite = cell.formatWrite;

// ============================================================================
// format - 1D Coordinates
// ============================================================================

test "format: 1D value 0" {
    const coord = Coordinate.init(.{0});
    const formatted = format(coord);
    try std.testing.expectEqualStrings("a", formatted.slice());
}

test "format: 1D value 25" {
    const coord = Coordinate.init(.{25});
    const formatted = format(coord);
    try std.testing.expectEqualStrings("z", formatted.slice());
}

test "format: 1D value 26" {
    const coord = Coordinate.init(.{26});
    const formatted = format(coord);
    try std.testing.expectEqualStrings("aa", formatted.slice());
}

test "format: 1D max value 255" {
    const coord = Coordinate.init(.{255});
    const formatted = format(coord);
    try std.testing.expectEqualStrings("iv", formatted.slice());
}

// ============================================================================
// format - 2D Coordinates
// ============================================================================

test "format: 2D origin a1" {
    const coord = Coordinate.init(.{ 0, 0 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("a1", formatted.slice());
}

test "format: 2D chess e4" {
    const coord = Coordinate.init(.{ 4, 3 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("e4", formatted.slice());
}

test "format: 2D chess h8" {
    const coord = Coordinate.init(.{ 7, 7 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("h8", formatted.slice());
}

test "format: 2D double digit a10" {
    const coord = Coordinate.init(.{ 0, 9 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("a10", formatted.slice());
}

test "format: 2D triple digit a100" {
    const coord = Coordinate.init(.{ 0, 99 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("a100", formatted.slice());
}

test "format: 2D max values iv256" {
    const coord = Coordinate.init(.{ 255, 255 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("iv256", formatted.slice());
}

// ============================================================================
// format - 3D Coordinates
// ============================================================================

test "format: 3D origin a1A" {
    const coord = Coordinate.init(.{ 0, 0, 0 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("a1A", formatted.slice());
}

test "format: 3D center b2B" {
    const coord = Coordinate.init(.{ 1, 1, 1 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("b2B", formatted.slice());
}

test "format: 3D diagonal c3C" {
    const coord = Coordinate.init(.{ 2, 2, 2 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("c3C", formatted.slice());
}

test "format: 3D max values iv256IV" {
    const coord = Coordinate.init(.{ 255, 255, 255 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("iv256IV", formatted.slice());
}

// ============================================================================
// format - Extended Alphabet
// ============================================================================

test "format: extended lowercase aa" {
    const coord = Coordinate.init(.{ 26, 0 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("aa1", formatted.slice());
}

test "format: extended lowercase az" {
    const coord = Coordinate.init(.{ 51, 0 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("az1", formatted.slice());
}

test "format: extended lowercase ba" {
    const coord = Coordinate.init(.{ 52, 0 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("ba1", formatted.slice());
}

test "format: extended uppercase AA" {
    const coord = Coordinate.init(.{ 0, 0, 26 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("a1AA", formatted.slice());
}

test "format: extended uppercase AZ" {
    const coord = Coordinate.init(.{ 0, 0, 51 });
    const formatted = format(coord);
    try std.testing.expectEqualStrings("a1AZ", formatted.slice());
}

// ============================================================================
// FormattedCoordinate.slice
// ============================================================================

test "FormattedCoordinate.slice: correct length 1D" {
    const coord = Coordinate.init(.{0});
    const formatted = format(coord);
    try std.testing.expectEqual(@as(usize, 1), formatted.slice().len);
}

test "FormattedCoordinate.slice: correct length 2D" {
    const coord = Coordinate.init(.{ 4, 3 });
    const formatted = format(coord);
    try std.testing.expectEqual(@as(usize, 2), formatted.slice().len);
}

test "FormattedCoordinate.slice: correct length 3D" {
    const coord = Coordinate.init(.{ 0, 0, 0 });
    const formatted = format(coord);
    try std.testing.expectEqual(@as(usize, 3), formatted.slice().len);
}

test "FormattedCoordinate.slice: correct length max" {
    const coord = Coordinate.init(.{ 255, 255, 255 });
    const formatted = format(coord);
    try std.testing.expectEqual(@as(usize, 7), formatted.slice().len);
}

// ============================================================================
// formatWrite
// ============================================================================

test "formatWrite: 2D" {
    var buf: [16]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);

    const coord = Coordinate.init(.{ 4, 3 });
    try formatWrite(stream.writer(), coord);

    try std.testing.expectEqualStrings("e4", stream.getWritten());
}

test "formatWrite: 3D" {
    var buf: [16]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);

    const coord = Coordinate.init(.{ 2, 2, 2 });
    try formatWrite(stream.writer(), coord);

    try std.testing.expectEqualStrings("c3C", stream.getWritten());
}

test "formatWrite: max values" {
    var buf: [16]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);

    const coord = Coordinate.init(.{ 255, 255, 255 });
    try formatWrite(stream.writer(), coord);

    try std.testing.expectEqualStrings("iv256IV", stream.getWritten());
}

test "formatWrite: to fixed buffer" {
    var buf: [16]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);

    const coord = Coordinate.init(.{ 4, 3 });
    try formatWrite(stream.writer(), coord);

    try std.testing.expectEqualStrings("e4", stream.getWritten());
}

// ============================================================================
// Edge Cases
// ============================================================================

test "format: boundary between single and double letter" {
    // z = 25 (single letter)
    const coord_z = Coordinate.init(.{25});
    try std.testing.expectEqualStrings("z", format(coord_z).slice());

    // aa = 26 (double letter)
    const coord_aa = Coordinate.init(.{26});
    try std.testing.expectEqualStrings("aa", format(coord_aa).slice());
}

test "format: boundary between single and double digit" {
    // 9 = index 8 (single digit)
    const coord_9 = Coordinate.init(.{ 0, 8 });
    try std.testing.expectEqualStrings("a9", format(coord_9).slice());

    // 10 = index 9 (double digit)
    const coord_10 = Coordinate.init(.{ 0, 9 });
    try std.testing.expectEqualStrings("a10", format(coord_10).slice());
}

test "format: boundary between double and triple digit" {
    // 99 = index 98 (double digit)
    const coord_99 = Coordinate.init(.{ 0, 98 });
    try std.testing.expectEqualStrings("a99", format(coord_99).slice());

    // 100 = index 99 (triple digit)
    const coord_100 = Coordinate.init(.{ 0, 99 });
    try std.testing.expectEqualStrings("a100", format(coord_100).slice());
}
