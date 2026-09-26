const std = @import("std");
const Writer = std.Io.Writer;
const Component = std.Uri.Component;

pub fn encode(w: *Writer, txt: []const u8) !void {
    try Component.percentEncode(w, txt, isUnreserved);
}

pub fn decode(w: *Writer, txt: []const u8) !void {
    const component: Component = .{ .percent_encoded = txt };
    try component.formatRaw(w);
}

/// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"   (RFC 3986 §2.3)
fn isUnreserved(c: u8) bool {
    return switch (c) {
        'A'...'Z', 'a'...'z', '0'...'9', '-', '.', '_', '~' => true,
        else => false,
    };
}

fn expectWritten(
    comptime f: fn (*Writer, []const u8) Writer.Error!void,
    input: []const u8,
    expected: []const u8,
) !void {
    var buf: [256]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try f(&w, input);
    try std.testing.expectEqualStrings(expected, w.buffered());
}

test "test encode spaces" {
    try expectWritten(encode, "hello world", "hello%20world");
}

test "test encode url" {
    try expectWritten(encode, "https://ziglang.org/documentation/master/std/#std.Io.File.stdout", "https%3A%2F%2Fziglang.org%2Fdocumentation%2Fmaster%2Fstd%2F%23std.Io.File.stdout");
}

test "test decode spaces" {
    try expectWritten(decode, "hello%20world", "hello world");
}

test "test decode url" {
    try expectWritten(decode, "https%3A%2F%2Fziglang.org%2Fdocumentation%2Fmaster%2Fstd%2F%23std.Io.File.stdout", "https://ziglang.org/documentation/master/std/#std.Io.File.stdout");
}
