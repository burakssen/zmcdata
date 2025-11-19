const std = @import("std");

const enums = @import("enums.zig");
const CommandNode = enums.CommandNode;

const ParserInfo = @import("parser_info.zig");

const Commands = @This();

root: CommandNode,
parsers: []ParserInfo,

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !Commands {
    const json_value = try std.json.innerParse(std.json.Value, allocator, source, options);

    if (json_value != .object) return error.UnexpectedToken;
    const obj = json_value.object;

    const root_val = obj.get("root") orelse return error.MissingField;
    const root = try CommandNode.jsonParseFromValue(allocator, root_val, options);

    const parsers_val = obj.get("parsers") orelse return error.MissingField;
    const parsers: []ParserInfo = if (parsers_val == .array) blk: {
        const arr = parsers_val.array;
        var parser_arr = try allocator.alloc(ParserInfo, arr.items.len);
        for (arr.items, 0..) |item, i| {
            parser_arr[i] = try ParserInfo.jsonParseFromValue(allocator, item, options);
        }
        break :blk parser_arr;
    } else return error.UnexpectedToken;

    return Commands{
        .root = root,
        .parsers = parsers,
    };
}
