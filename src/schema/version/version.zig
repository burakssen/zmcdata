const std = @import("std");

const Version = @This();

version: ?i32 = null,
minecraftVersion: ?[]const u8 = null,
majorVersion: ?[]const u8 = null,
releaseType: ?[]const u8 = null,
