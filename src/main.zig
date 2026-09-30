const std = @import("std");
const clap = @import("clap");
const zurl = @import("zurlencode.zig");

const File = std.Io.File;
const Reader = std.Io.Reader;

pub fn main(init: std.process.Init) !void {
    // Defines the inputs for types:
    //   e - encoding
    //   d - decoding
    const EncodeDecodeType = enum { e, d };

    const parsers = comptime .{
        .EDT = clap.parsers.enumeration(EncodeDecodeType),
        .STR = clap.parsers.string,
    };

    const params = comptime clap.parseParamsComptime(
        \\-h, --help        Display this help and exit.
        \\-t, --type <EDT>  Specify the type: e - encode, d - decode.
        \\<STR>             The string to be de-/encoded.
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.helpToFile(init.io, .stderr(), clap.Help, &params, .{});

    const pos_argument = res.positionals[0];

    var out_buf: [4096]u8 = undefined;
    var stdout = File.stdout().writerStreaming(init.io, &out_buf);
    const out = &stdout.interface;

    var in_buf: [64 * 1024]u8 = undefined;
    var stdin = File.stdin().readerStreaming(init.io, &in_buf);
    var arg_reader: Reader = .fixed(pos_argument orelse "");

    const in: *Reader = if (pos_argument == null) &stdin.interface else &arg_reader;

    switch (res.args.type orelse EncodeDecodeType.e) {
        .e => try zurl.transformLines(out, in, zurl.encode),
        .d => try zurl.transformLines(out, in, zurl.decode),
    }

    try out.writeByte('\n');
    try out.flush();
}
