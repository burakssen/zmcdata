const std = @import("std");

pub const RecipeItem = union(enum) {
    id_only: ?i32,
    id_metadata: struct {
        id: ?i32,
        metadata: i32,
    },
    full: struct {
        id: ?i32,
        metadata: ?i32 = null,
        count: ?i32 = null,
    },

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !RecipeItem {
        _ = allocator;
        _ = options;

        // Case 1: Just an ID (integer or null)
        if (source == .integer) {
            return RecipeItem{ .id_only = @intCast(source.integer) };
        }
        if (source == .null) {
            return RecipeItem{ .id_only = null };
        }

        // Case 2: Array [id, metadata]
        if (source == .array) {
            const arr = source.array;
            if (arr.items.len != 2) return error.LengthMismatch;

            const id: ?i32 = if (arr.items[0] == .integer)
                @intCast(arr.items[0].integer)
            else if (arr.items[0] == .null)
                null
            else
                return error.UnexpectedToken;

            const metadata: i32 = if (arr.items[1] == .integer)
                @intCast(arr.items[1].integer)
            else
                return error.UnexpectedToken;

            return RecipeItem{ .id_metadata = .{ .id = id, .metadata = metadata } };
        }

        // Case 3: Object {id, metadata?, count?}
        if (source == .object) {
            const obj = source.object;

            const id_val = obj.get("id") orelse return error.MissingField;
            const id: ?i32 = if (id_val == .integer)
                @intCast(id_val.integer)
            else if (id_val == .null)
                null
            else
                return error.UnexpectedToken;

            const metadata: ?i32 = if (obj.get("metadata")) |m|
                if (m == .integer) @intCast(m.integer) else null
            else
                null;

            const count: ?i32 = if (obj.get("count")) |c|
                if (c == .integer) @intCast(c.integer) else null
            else
                null;

            return RecipeItem{ .full = .{ .id = id, .metadata = metadata, .count = count } };
        }

        return error.UnexpectedToken;
    }
};

pub const BedrockRecipeType = enum {
    multi,
    cartography_table,
    stonecutter,
    crafting_table,
    crafting_table_shapeless,
    shulker_box,
    furnace,
    blast_furnace,
    smoker,
    soul_campfire,
    campfire,
    smithing_table,
};

const Recipe = union(enum) {
    const ShapedRecipe = @import("shaped_recipe.zig");
    const ShapelessRecipe = @import("shapeless_recipe.zig");

    shaped: ShapedRecipe,
    shapeless: ShapelessRecipe,

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !Recipe {
        if (source != .object) return error.UnexpectedToken;
        const obj = source.object;

        // Check if it's a shaped recipe (has inShape)
        if (obj.get("inShape")) |_| {
            return Recipe{ .shaped = try ShapedRecipe.jsonParseFromValue(allocator, source, options) };
        }

        // Check if it's a shapeless recipe (has ingredients)
        if (obj.get("ingredients")) |_| {
            return Recipe{ .shapeless = try ShapelessRecipe.jsonParseFromValue(allocator, source, options) };
        }

        return error.MissingField;
    }
};

pub const RecipeEntry = union(enum) {
    const BedrockRecipe = @import("bedrock_recipe.zig");

    java: []Recipe,
    bedrock: std.json.Parsed(BedrockRecipe),

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !RecipeEntry {
        // Case 1: Array of Java recipes
        if (source == .array) {
            const arr = source.array;
            var recipes = try allocator.alloc(Recipe, arr.items.len);
            for (arr.items, 0..) |item, i| {
                recipes[i] = try Recipe.jsonParseFromValue(allocator, item, options);
            }
            return RecipeEntry{ .java = recipes };
        }

        if (source == .object) return RecipeEntry{ .bedrock = try std.json.parseFromValue(BedrockRecipe, allocator, source, options) };

        return error.UnexpectedToken;
    }
};

pub const Ingredient = struct {
    name: []const u8,
    count: i32,
    metadata: ?i32 = null,
    nbt: ?Nbt = null,
};

pub const Nbt = struct {
    version: i32,
    nbt: struct {
        type: []const u8,
        name: []const u8,
        value: NbtValue,
    },
};

pub const NbtValue = struct {
    FireworksItem: ?FireworksItemType = null,
    customColor: ?CustomColor = null,
    Fireworks: ?FireworksType = null,

    const FireworksItemType = struct {
        type: []const u8,
        value: FireworksItemValue,
    };

    const FireworksItemValue = struct {
        FireworkColor: FireworkColor,
        FireworkFade: FireworkFade,
        FireworkFlicker: FireworkFlicker,
        FireworkTrail: FireworkTrail,
        FireworkType: FireworkType,
    };

    const FireworkColor = struct {
        type: []const u8,
        value: []i32,
    };

    const FireworkFade = struct {
        type: []const u8,
        value: []i32,
    };

    const FireworkFlicker = struct {
        type: []const u8,
        value: i32,
    };

    const FireworkTrail = struct {
        type: []const u8,
        value: i32,
    };

    const FireworkType = struct {
        type: []const u8,
        value: i32,
    };

    const CustomColor = struct {
        type: []const u8,
        value: i64,
    };

    const FireworksType = struct {
        type: []const u8,
        value: FireworksValueType,
    };

    const FireworksValueType = struct {
        Explosions: ExplosionsType,
        Flight: FlightType,
    };

    const ExplosionsType = struct {
        type: []const u8,
        value: ExplosionsValue,
    };

    const ExplosionsValue = struct {
        type: []const u8,
        value: []FireworksItemValue,
    };

    const FlightType = struct {
        type: []const u8,
        value: i32,
    };

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !NbtValue {
        if (source != .object) return error.UnexpectedToken;
        const obj = source.object;

        var result = NbtValue{};

        if (obj.get("FireworksItem")) |fireworks_item_value| {
            const parsed = try std.json.parseFromValue(FireworksItemType, allocator, fireworks_item_value, options);
            result.FireworksItem = parsed.value;
        }

        if (obj.get("customColor")) |val| {
            const parsed = try std.json.parseFromValue(CustomColor, allocator, val, options);
            result.customColor = parsed.value;
        }

        if (obj.get("Fireworks")) |val| {
            const parsed = try std.json.parseFromValue(FireworksType, allocator, val, options);
            result.Fireworks = parsed.value;
        }

        return result;
    }

    pub fn deinit(self: NbtValue, allocator: std.mem.Allocator) void {
        if (self.FireworksItem) |item| {
            allocator.free(item);
        }

        if (self.customColor) |color| {
            allocator.free(color);
        }

        if (self.Fireworks) |fireworks| {
            allocator.free(fireworks);
        }
    }
};
