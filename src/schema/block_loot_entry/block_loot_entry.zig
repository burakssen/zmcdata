const std = @import("std");

const BlockState = @import("../common/block_state.zig");
const BlockItemDrop = @import("block_item_drop.zig");

pub const BlockLootEntry = @This();

block: []const u8,
states: ?[]BlockState = null,
drops: []BlockItemDrop,

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !BlockLootEntry {
    const json_value = try std.json.innerParse(std.json.Value, allocator, source, options);

    if (json_value != .object) return error.UnexpectedToken;
    const obj = json_value.object;

    const getRequired = struct {
        fn call(object: std.json.ObjectMap, comptime field: []const u8) !std.json.Value {
            return object.get(field) orelse return error.MissingField;
        }
    }.call;

    const block_val = try getRequired(obj, "block");
    const block = if (block_val == .string) block_val.string else return error.UnexpectedToken;

    const states: ?[]BlockState = if (obj.get("states")) |s| blk: {
        if (s != .array) return error.UnexpectedToken;
        const arr = s.array;
        var sts = try allocator.alloc(BlockState, arr.items.len);
        for (arr.items, 0..) |item, i| {
            sts[i] = try std.json.innerParseFromValue(BlockState, allocator, item, options);
        }
        break :blk sts;
    } else null;

    const drops_val = try getRequired(obj, "drops");
    const drops: []BlockItemDrop = if (drops_val == .array) blk: {
        const arr = drops_val.array;
        var drops_arr = try allocator.alloc(BlockItemDrop, arr.items.len);
        for (arr.items, 0..) |item, i| {
            drops_arr[i] = try BlockItemDrop.jsonParseFromValue(allocator, item, options);
        }
        break :blk drops_arr;
    } else return error.UnexpectedToken;

    return BlockLootEntry{
        .block = block,
        .states = states,
        .drops = drops,
    };
}

pub fn deinit(self: *BlockLootEntry, allocator: std.mem.Allocator) void {
    if (self.states) |*s| {
        s.deinit();
    }
    for (self.drops) |drop| {
        allocator.free(drop.stackSizeRange);
    }
    allocator.free(self.drops);
}
