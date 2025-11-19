const std = @import("std");

const enums = @import("enums.zig");
const Modifier = enums.Modifier;

const ParserInfo = @This();

parser: []const u8,
modifier: ?Modifier,
examples: [][]const u8,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !ParserInfo {
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

    const examples_val = obj.get("examples") orelse return error.MissingField;
    const examples: [][]const u8 = if (examples_val == .array) blk: {
        const arr = examples_val.array;
        var ex_arr = try allocator.alloc([]const u8, arr.items.len);
        for (arr.items, 0..) |item, i| {
            ex_arr[i] = if (item == .string) item.string else return error.UnexpectedToken;
        }
        break :blk ex_arr;
    } else return error.UnexpectedToken;

    return ParserInfo{
        .parser = parser,
        .modifier = modifier,
        .examples = examples,
    };
}
