const std = @import("std");

const enums = @import("enums.zig");
const RecipeItem = enums.RecipeItem;

const ShapelessRecipe = @This();

result: RecipeItem,
ingredients: []RecipeItem,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !ShapelessRecipe {
    if (source != .object) return error.UnexpectedToken;
    const obj = source.object;

    const result_val = obj.get("result") orelse return error.MissingField;
    const result = try RecipeItem.jsonParseFromValue(allocator, result_val, options);

    const ingredients_val = obj.get("ingredients") orelse return error.MissingField;
    if (ingredients_val != .array) return error.UnexpectedToken;
    const arr = ingredients_val.array;

    var ingredients = try allocator.alloc(RecipeItem, arr.items.len);
    for (arr.items, 0..) |item, i| {
        ingredients[i] = try RecipeItem.jsonParseFromValue(allocator, item, options);
    }

    return ShapelessRecipe{
        .result = result,
        .ingredients = ingredients,
    };
}
