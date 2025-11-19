const std = @import("std");

const ItemVariation = @This();

metadata: u32,
displayName: []const u8,
id: ?u32 = null,
name: ?[]const u8 = null,
stackSize: ?u32 = null,
enchantCategories: ?[][]const u8 = null,
