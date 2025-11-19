const std = @import("std");

const ProtocolVersion = @This();

version: i32,
dataVersion: ?i32 = null,
minecraftVersion: []const u8,
majorVersion: []const u8,
usesNetty: ?bool = null,
releaseType: ?[]const u8 = null,
