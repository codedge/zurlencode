const std = @import("std");
const Writer = std.Io.Writer;
const Component = std.Uri.Component;
const Reader = std.Io.Reader;

pub fn transformLines(
    w: *Writer,
    r: *Reader,
    comptime f: fn (*Writer, []const u8) Writer.Error!void,
) !void {
    while (true) {
        const line = r.takeDelimiterExclusive('\n') catch |err| {
            if (err == error.EndOfStream) return;
            return err;
        };

        try f(w, line);

        if (r.bufferedLen() == 0) return;
        r.toss(1);
        try w.writeByte('\n');
    }
}

pub fn encode(w: *Writer, txt: []const u8) !void {
    try Component.percentEncode(w, txt, isUnreserved);
}

pub fn decode(w: *Writer, txt: []const u8) !void {
    const component: Component = .{ .percent_encoded = txt };
    try component.formatRaw(w);
}

/// Unreserved Characters - see RFC 3986, §2.3
fn isUnreserved(c: u8) bool {
    return switch (c) {
        'A'...'Z', 'a'...'z', '0'...'9', '-', '.', '_', '~' => true,
        else => false,
    };
}

fn expectWritten(
    comptime f: fn (*Writer, []const u8) Writer.Error!void,
    actual: []const []const u8,
    expected: []const []const u8,
) !void {
    // Join the input lines into one byte slice so no test spells out `\n`.
    const text = try std.mem.join(std.testing.allocator, "\n", actual);
    defer std.testing.allocator.free(text);

    var buf: [1024]u8 = undefined;
    var w: Writer = .fixed(&buf);
    var r: Reader = .fixed(text);

    try transformLines(&w, &r, f);

    if (expected.len == 0) {
        return;
    }

    var lines = std.mem.splitScalar(u8, w.buffered(), '\n');
    for (expected) |want| {
        const got = lines.next() orelse return error.TooFewLines;
        try std.testing.expectEqualStrings(want, got);
    }
    try std.testing.expect(lines.next() == null);
}

//
// TEST encoding
//
test "encode no input no output" {
    try expectWritten(encode, &.{}, &.{});
}

test "encode spaces" {
    try expectWritten(encode, &.{"hello world"}, &.{"hello%20world"});
}

test "test encode spaces but do not add a trailing new line at the end of the input" {
    try expectWritten(encode, &.{ "foo bar", "baz quux" }, &.{ "foo%20bar", "baz%20quux" });
}

test "encode url" {
    try expectWritten(encode, &.{"https://ziglang.org/documentation/master/std/#std.Io.File.stdout"}, &.{"https%3A%2F%2Fziglang.org%2Fdocumentation%2Fmaster%2Fstd%2F%23std.Io.File.stdout"});
}

//
// TEST decoding
//
test "decode spaces" {
    try expectWritten(decode, &.{"hello%20world"}, &.{"hello world"});
}

test "decode new lines" {
    try expectWritten(decode, &.{"foo%20bar\nbaz%20quux"}, &.{ "foo bar", "baz quux" });
}

test "decode url" {
    try expectWritten(decode, &.{"https%3A%2F%2Fziglang.org%2Fdocumentation%2Fmaster%2Fstd%2F%23std.Io.File.stdout"}, &.{"https://ziglang.org/documentation/master/std/#std.Io.File.stdout"});
}
