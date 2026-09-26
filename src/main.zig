const std = @import("std");
const clap = @import("clap");
const zurl = @import("zurlencode.zig");

const ArgumentError = error{
    MissingInput,
    MissingEncodeDecodeType,
};

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
        \\-h, --help            Display this help and exit.
        \\-t, --type <EDT>    Specify the type: e - encode, d - decode.
        \\<STR>                 The string to be de-/encoded.
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

    const input = res.positionals[0] orelse return error.MissingInput;
    const edt = res.args.type orelse EncodeDecodeType.e;

    var out_buf: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &out_buf);
    const out = &stdout.interface;

    switch (edt) {
        .d => return zurl.decode(out, input),
        .e => return zurl.encode(out, input),
    }

    try out.writeByte('\n');
    try out.flush();
}
