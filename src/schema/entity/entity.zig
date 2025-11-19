const std = @import("std");

const Entity = @This();

id: u32,
internalId: ?u32 = null,
displayName: []const u8,
name: []const u8,
type: []const u8,
width: ?f32,
height: ?f32,
length: ?f32 = null,
offset: ?f32 = null,
category: ?[]const u8 = null,
metadataKeys: ?[][]const u8 = null,
