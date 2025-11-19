const std = @import("std");

const Instrument = @This();

id: u32,
name: []const u8,
sound: ?[]const u8 = null,
