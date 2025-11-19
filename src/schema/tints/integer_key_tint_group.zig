const std = @import("std");

const IntegerKeyTintEntry = @import("integer_key_tint_entry.zig");

const IntegerKeyTintGroup = @This();

data: []IntegerKeyTintEntry,
default: ?i32 = null,
