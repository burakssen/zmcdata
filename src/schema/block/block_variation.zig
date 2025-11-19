const std = @import("std");

const BlockVariation = @This();

metadata: u32,
displayName: []const u8,
description: []const u8 = "",
