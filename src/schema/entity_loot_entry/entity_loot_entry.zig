const std = @import("std");

const EntityItemDrop = @import("entity_item_drop.zig");

const EntityLootEntry = @This();

entity: []const u8,
drops: []EntityItemDrop,
