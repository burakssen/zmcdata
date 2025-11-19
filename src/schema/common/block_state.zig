const std = @import("std");

const enums = @import("enums.zig");

const PropertyType = enums.PropertyType;
const PropertyValue = enums.PropertyValue;

const BlockState = @This();

name: []const u8,
type: PropertyType,
values: ?[]PropertyValue = null,
num_values: u32,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !BlockState {
    if (source != .object) return error.UnexpectedToken;
    const obj = source.object;

    const name_val = obj.get("name") orelse return error.MissingField;
    if (name_val != .string) return error.UnexpectedToken;
    const name = name_val.string;

    const type_val = obj.get("type") orelse return error.MissingField;
    if (type_val != .string) return error.UnexpectedToken;
    const property_type = std.meta.stringToEnum(PropertyType, type_val.string) orelse return error.InvalidEnumTag;

    const num_values_val = obj.get("num_values") orelse return error.MissingField;
    const num_values: u32 = switch (num_values_val) {
        .integer => @as(u32, @intCast(num_values_val.integer)),
        .number_string => try std.fmt.parseInt(u32, num_values_val.number_string, 10),
        else => return error.UnexpectedToken,
    };

    const values: ?[]PropertyValue = if (obj.get("values")) |v| blk: {
        if (v != .array) return error.UnexpectedToken;
        const arr = v.array;
        var vals = try allocator.alloc(PropertyValue, arr.items.len);
        for (arr.items, 0..) |item, i| {
            vals[i] = try PropertyValue.jsonParseFromValue(allocator, item, options);
        }
        break :blk vals;
    } else null;

    return BlockState{
        .name = name,
        .type = property_type,
        .values = values,
        .num_values = num_values,
    };
}
