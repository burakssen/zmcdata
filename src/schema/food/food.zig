const std = @import("std");

const FoodVariation = @import("food_variation.zig");

const Food = @This();

id: u32,
displayName: []const u8,
stackSize: u32,
name: []const u8,
foodPoints: f32,
saturation: f32,
effectiveQuality: f32,
saturationRatio: f32,
variations: ?[]FoodVariation = null,
