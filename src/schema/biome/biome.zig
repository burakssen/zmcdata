const std = @import("std");

const enums = @import("enums.zig");
const Precipitation = enums.Precipitation;

const Climate = @import("climate.zig");

const Biome = @This();

id: u32,
name: []const u8,
category: []const u8,
temperature: f32,
precipitation: ?Precipitation = null,
has_precipitation: ?bool = null,
dimension: []const u8,
displayName: []const u8,
color: u32,
rainfall: ?f32 = null,
depth: ?f32 = null,
climates: ?[]Climate = null,
name_legacy: ?[]const u8 = null,
parent: ?[]const u8 = null,
child: ?u32 = null,
