const std = @import("std");

const Attribute = @This();

resource: []const u8,
name: []const u8,
min: f64,
max: f64,
default: f64,
