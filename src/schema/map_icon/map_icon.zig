const std = @import("std");

const MapIcon = @This();

id: u32,
name: []const u8,
appearance: ?[]const u8 = null,
visibleInItemFrame: bool,
