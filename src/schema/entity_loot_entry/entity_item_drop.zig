const std = @import("std");

const EntityItemDrop = @This();

item: []const u8,
metadata: ?u8 = null,
dropChance: f32,
stackSizeRange: []?f32,
playerKill: ?bool = null,
