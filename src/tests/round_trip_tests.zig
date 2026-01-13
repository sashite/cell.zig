//! Round-trip tests for CELL coordinate encoding.
//!
//! Verifies that parse(format(coord)) == coord and format(parse(s)) == s.

const std = @import("std");
const cell = @import("../cell.zig");

const Coordinate = cell.Coordinate;
const parse = cell.parse;
const format = cell.format;

// ============================================================================
// String → Coordinate → String
// ============================================================================

test "round-trip: string → coordinate → string (1D)" {
    const cases = [_][]const u8{
        "a",
        "z",
        "aa",
        "iv",
    };

    for (cases) |original| {
        const coord = try parse(original);
        const formatted = format(coord);
        try std.testing.expectEqualStrings(original, formatted.slice());
    }
}

test "round-trip: string → coordinate → string (2D)" {
    const cases = [_][]const u8{
        "a1",
        "e4",
        "h8",
        "z9",
        "a10",
        "a99",
        "a100",
        "a256",
        "aa1",
        "az1",
        "ba1",
        "iv256",
    };

    for (cases) |original| {
        const coord = try parse(original);
        const formatted = format(coord);
        try std.testing.expectEqualStrings(original, formatted.slice());
    }
}

test "round-trip: string → coordinate → string (3D)" {
    const cases = [_][]const u8{
        "a1A",
        "b2B",
        "c3C",
        "e4D",
        "z9Z",
        "a1AA",
        "a1AZ",
        "iv256IV",
    };

    for (cases) |original| {
        const coord = try parse(original);
        const formatted = format(coord);
        try std.testing.expectEqualStrings(original, formatted.slice());
    }
}

// ============================================================================
// Coordinate → String → Coordinate
// ============================================================================

test "round-trip: coordinate → string → coordinate (1D)" {
    const cases = [_][1]u8{
        .{0},
        .{25},
        .{26},
        .{255},
    };

    for (cases) |indices| {
        const original = Coordinate.init(.{indices[0]});
        const formatted = format(original);
        const parsed = try parse(formatted.slice());

        try std.testing.expectEqual(original.dimensions, parsed.dimensions);
        try std.testing.expectEqualSlices(u8, original.slice(), parsed.slice());
    }
}

test "round-trip: coordinate → string → coordinate (2D)" {
    const cases = [_][2]u8{
        .{ 0, 0 },
        .{ 4, 3 },
        .{ 7, 7 },
        .{ 25, 8 },
        .{ 26, 9 },
        .{ 255, 255 },
    };

    for (cases) |indices| {
        const original = Coordinate.init(.{ indices[0], indices[1] });
        const formatted = format(original);
        const parsed = try parse(formatted.slice());

        try std.testing.expectEqual(original.dimensions, parsed.dimensions);
        try std.testing.expectEqualSlices(u8, original.slice(), parsed.slice());
    }
}

test "round-trip: coordinate → string → coordinate (3D)" {
    const cases = [_][3]u8{
        .{ 0, 0, 0 },
        .{ 1, 1, 1 },
        .{ 2, 2, 2 },
        .{ 4, 3, 3 },
        .{ 25, 8, 25 },
        .{ 26, 9, 26 },
        .{ 255, 255, 255 },
    };

    for (cases) |indices| {
        const original = Coordinate.init(.{ indices[0], indices[1], indices[2] });
        const formatted = format(original);
        const parsed = try parse(formatted.slice());

        try std.testing.expectEqual(original.dimensions, parsed.dimensions);
        try std.testing.expectEqualSlices(u8, original.slice(), parsed.slice());
    }
}

// ============================================================================
// Exhaustive Tests (Boundary Values)
// ============================================================================

test "round-trip: all single-letter lowercase values" {
    // Test a-z (0-25)
    for (0..26) |i| {
        const original = Coordinate.init(.{@as(u8, @intCast(i))});
        const formatted = format(original);
        const parsed = try parse(formatted.slice());
        try std.testing.expectEqualSlices(u8, original.slice(), parsed.slice());
    }
}

test "round-trip: boundary values for each dimension type" {
    // Lowercase boundaries
    const lowercase_bounds = [_]u8{ 0, 25, 26, 51, 52, 255 };
    // Numeric boundaries (as 0-indexed)
    const numeric_bounds = [_]u8{ 0, 8, 9, 98, 99, 255 };
    // Uppercase boundaries
    const uppercase_bounds = [_]u8{ 0, 25, 26, 51, 52, 255 };

    for (lowercase_bounds) |l| {
        for (numeric_bounds) |n| {
            for (uppercase_bounds) |u| {
                const original = Coordinate.init(.{ l, n, u });
                const formatted = format(original);
                const parsed = try parse(formatted.slice());
                try std.testing.expectEqualSlices(u8, original.slice(), parsed.slice());
            }
        }
    }
}

// ============================================================================
// Comptime Round-trip
// ============================================================================

test "round-trip: comptime parse then format" {
    const coord = comptime cell.parseComptime("e4");
    const formatted = format(coord);
    try std.testing.expectEqualStrings("e4", formatted.slice());
}

test "round-trip: comptime with max values" {
    const coord = comptime cell.parseComptime("iv256IV");
    const formatted = format(coord);
    try std.testing.expectEqualStrings("iv256IV", formatted.slice());
}
