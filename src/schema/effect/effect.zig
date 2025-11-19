const std = @import("std");

const enums = @import("enums.zig");
const EffectType = enums.EffectType;

const Effect = @This();

id: u32,
displayName: []const u8,
name: []const u8,
type: EffectType,
