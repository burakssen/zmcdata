const std = @import("std");

const enums = @import("enums.zig");
const RecipeEntry = enums.RecipeEntry;

const Recipes = @This();

recipes: std.StringHashMap(RecipeEntry),

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !Recipes {
    const json_value = try std.json.innerParse(std.json.Value, allocator, source, options);

    if (json_value != .object) return error.UnexpectedToken;
    const obj = json_value.object;

    var recipes = std.StringHashMap(RecipeEntry).init(allocator);
    errdefer recipes.deinit();

    var it = obj.iterator();
    while (it.next()) |entry| {
        const recipe_entry = try RecipeEntry.jsonParseFromValue(allocator, entry.value_ptr.*, options);
        try recipes.put(entry.key_ptr.*, recipe_entry);
    }

    return Recipes{ .recipes = recipes };
}

pub fn deinit(self: *Recipes) void {
    self.recipes.deinit();
}
