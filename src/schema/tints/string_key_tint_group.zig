const std = @import("std");

const StringKeyTintEntry = @import("string_key_tint_entry.zig");

const StringKeyTintGroup = @This();

data: []StringKeyTintEntry,
default: ?i32 = null,
