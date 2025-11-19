const std = @import("std");

const enums = @import("enums.zig");
const BedrockRecipeType = enums.BedrockRecipeType;

const BedrockRecipe = @This();

name: ?[]const u8,
type: BedrockRecipeType,
ingredients: []std.json.Value,
input: ?[]std.json.Value = null,
output: []std.json.Value,
priority: ?f32 = null,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !BedrockRecipe {
    _ = options;

    if (source != .object) return error.UnexpectedToken;
    const obj = source.object;

    const name_val = obj.get("name") orelse return error.MissingField;
    const name: ?[]const u8 = if (name_val == .string)
        name_val.string
    else if (name_val == .null)
        null
    else
        return error.UnexpectedToken;

    const type_val = obj.get("type") orelse return error.MissingField;
    const type_str = if (type_val == .string) type_val.string else return error.UnexpectedToken;
    const recipe_type = std.meta.stringToEnum(BedrockRecipeType, type_str) orelse return error.InvalidEnumTag;

    const ingredients_val = obj.get("ingredients") orelse return error.MissingField;
    if (ingredients_val != .array) return error.UnexpectedToken;
    const ingredients = try allocator.dupe(std.json.Value, ingredients_val.array.items);

    const input: ?[]std.json.Value = if (obj.get("input")) |inp| blk: {
        if (inp != .array) return error.UnexpectedToken;
        break :blk try allocator.dupe(std.json.Value, inp.array.items);
    } else null;

    const output_val = obj.get("output") orelse return error.MissingField;
    if (output_val != .array) return error.UnexpectedToken;
    const output = try allocator.dupe(std.json.Value, output_val.array.items);

    const priority: ?f32 = if (obj.get("priority")) |p| switch (p) {
        .integer => |i| @floatFromInt(i),
        .float => |f| @floatCast(f),
        .number_string => |ns| try std.fmt.parseFloat(f32, ns),
        else => null,
    } else null;

    return BedrockRecipe{
        .name = name,
        .type = recipe_type,
        .ingredients = ingredients,
        .input = input,
        .output = output,
        .priority = priority,
    };
}
