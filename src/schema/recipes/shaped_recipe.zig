const std = @import("std");

const enums = @import("enums.zig");
const RecipeItem = enums.RecipeItem;

const ShapedRecipe = @This();

result: RecipeItem,
inShape: [][]RecipeItem,
outShape: ?[][]RecipeItem = null,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !ShapedRecipe {
    if (source != .object) return error.UnexpectedToken;
    const obj = source.object;

    const result_val = obj.get("result") orelse return error.MissingField;
    const result = try RecipeItem.jsonParseFromValue(allocator, result_val, options);

    const in_shape_val = obj.get("inShape") orelse return error.MissingField;
    const in_shape = try parseShape(allocator, in_shape_val, options);

    const out_shape: ?[][]RecipeItem = if (obj.get("outShape")) |os|
        try parseShape(allocator, os, options)
    else
        null;

    return ShapedRecipe{
        .result = result,
        .inShape = in_shape,
        .outShape = out_shape,
    };
}

fn parseShape(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) ![][]RecipeItem {
    if (source != .array) return error.UnexpectedToken;
    const arr = source.array;

    var shape = try allocator.alloc([]RecipeItem, arr.items.len);
    for (arr.items, 0..) |row_val, i| {
        if (row_val != .array) return error.UnexpectedToken;
        const row_arr = row_val.array;

        var row = try allocator.alloc(RecipeItem, row_arr.items.len);
        for (row_arr.items, 0..) |item_val, j| {
            row[j] = try RecipeItem.jsonParseFromValue(allocator, item_val, options);
        }
        shape[i] = row;
    }

    return shape;
}
