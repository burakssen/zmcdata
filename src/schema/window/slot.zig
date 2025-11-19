const std = @import("std");

const Slot = @This();

name: []const u8,
index: u32,
size: ?u32 = null,
