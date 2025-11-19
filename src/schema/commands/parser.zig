const std = @import("std");

const enums = @import("enums.zig");
const Modifier = enums.Modifier;

const Parser = @This();

parser: []const u8,
modifier: ?Modifier,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !Parser {
    if (source != .object) return error.UnexpectedToken;
    const obj = source.object;

    const parser_val = obj.get("parser") orelse return error.MissingField;
    const parser = if (parser_val == .string) parser_val.string else return error.UnexpectedToken;

    const modifier = if (obj.get("modifier")) |mod_val| blk: {
        if (mod_val == .null) {
            break :blk null;
        } else {
            break :blk try Modifier.jsonParseFromValue(allocator, mod_val, options);
        }
    } else null;

    return Parser{
        .parser = parser,
        .modifier = modifier,
    };
}
