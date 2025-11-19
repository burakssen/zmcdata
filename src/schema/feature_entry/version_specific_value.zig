const std = @import("std");

const VersionSpecificValue = @This();

value: std.json.Value,
version: ?[]const u8 = null,
versions: ?[2][]const u8 = null,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !VersionSpecificValue {
    _ = allocator;
    _ = options;

    if (source != .object) return error.UnexpectedToken;
    const obj = source.object;

    const value = obj.get("value") orelse return error.MissingField;

    const version: ?[]const u8 = if (obj.get("version")) |v|
        if (v == .string) v.string else null
    else
        null;

    const versions: ?[2][]const u8 = if (obj.get("versions")) |v| blk: {
        if (v != .array) return error.UnexpectedToken;
        const arr = v.array;
        if (arr.items.len != 2) return error.LengthMismatch;

        const min_ver = if (arr.items[0] == .string) arr.items[0].string else return error.UnexpectedToken;
        const max_ver = if (arr.items[1] == .string) arr.items[1].string else return error.UnexpectedToken;

        break :blk [2][]const u8{ min_ver, max_ver };
    } else null;

    return VersionSpecificValue{
        .value = value,
        .version = version,
        .versions = versions,
    };
}
