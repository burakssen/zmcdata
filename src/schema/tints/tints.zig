const std = @import("std");

const StringKeyTintGroup = @import("string_key_tint_group.zig");
const IntegerKeyTintGroup = @import("integer_key_tint_group.zig");

pub const Tints = @This();

grass: StringKeyTintGroup,
foliage: StringKeyTintGroup,
water: StringKeyTintGroup,
redstone: IntegerKeyTintGroup,
constant: StringKeyTintGroup,
