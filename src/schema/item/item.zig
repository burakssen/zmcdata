const std = @import("std");

const ItemVariation = @import("item_variation.zig");

const Item = @This();

id: u32,
displayName: []const u8,
stackSize: u32,
name: []const u8,
enchantCategories: ?[][]const u8 = null,
repairWith: ?[][]const u8 = null,
maxDurability: ?u32 = null,
durability: ?u32 = null,
metadata: ?u32 = null,
blockStateId: ?u32 = null,
variations: ?[]ItemVariation = null,
