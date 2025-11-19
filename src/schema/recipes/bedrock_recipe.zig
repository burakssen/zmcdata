const std = @import("std");
const enums = @import("enums.zig");
const BedrockRecipeType = enums.BedrockRecipeType;
const Ingredient = enums.Ingredient;

const BedrockRecipe = @This();

name: ?[]const u8,
type: BedrockRecipeType,
ingredients: []Ingredient,
input: ?[][]i32 = null,
output: []Ingredient,
priority: ?f32 = null,
