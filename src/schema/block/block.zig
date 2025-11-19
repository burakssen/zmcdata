const std = @import("std");

const enums = @import("enums.zig");

const BoundingBox = enums.BoundingBox;
const DropItem = enums.DropItem;

const BlockVariation = @import("block_variation.zig");
const BlockState = @import("../common/block_state.zig");

const Block = @This();

id: u32,
displayName: []const u8,
name: []const u8,
hardness: ?f32,
stackSize: u32,
diggable: bool,
boundingBox: BoundingBox,
material: ?[]const u8 = null,
harvestTools: ?std.StringHashMap(bool) = null,
variations: ?[]BlockVariation = null,
states: ?[]BlockState = null,
drops: []DropItem,
transparent: bool,
emitLight: u8,
filterLight: u8,
minStateId: ?u32 = null,
maxStateId: ?u32 = null,
defaultState: ?u32 = null,
resistance: ?f32 = null,

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !Block {
    const json_value = try std.json.innerParse(std.json.Value, allocator, source, options);

    if (json_value != .object) return error.UnexpectedToken;
    const obj = json_value.object;

    const getRequired = struct {
        fn call(object: std.json.ObjectMap, comptime field: []const u8) !std.json.Value {
            return object.get(field) orelse return error.MissingField;
        }
    }.call;

    const id_val = try getRequired(obj, "id");
    const id: u32 = switch (id_val) {
        .integer => |i| @intCast(i),
        else => return error.UnexpectedToken,
    };

    const display_name_val = try getRequired(obj, "displayName");
    const display_name = if (display_name_val == .string) display_name_val.string else return error.UnexpectedToken;

    const name_val = try getRequired(obj, "name");
    const name = if (name_val == .string) name_val.string else return error.UnexpectedToken;

    const hardness_val = try getRequired(obj, "hardness");
    const hardness: ?f32 = switch (hardness_val) {
        .integer => |i| @floatFromInt(i),
        .float => |f| @floatCast(f),
        .number_string => |ns| try std.fmt.parseFloat(f32, ns),
        .null => null,
        else => return error.UnexpectedToken,
    };

    const stack_size_val = try getRequired(obj, "stackSize");
    const stack_size: u32 = switch (stack_size_val) {
        .integer => |i| @intCast(i),
        else => return error.UnexpectedToken,
    };

    const diggable_val = try getRequired(obj, "diggable");
    const diggable = if (diggable_val == .bool) diggable_val.bool else return error.UnexpectedToken;

    const bounding_box_val = try getRequired(obj, "boundingBox");
    const bounding_box_str = if (bounding_box_val == .string) bounding_box_val.string else return error.UnexpectedToken;
    const bounding_box = std.meta.stringToEnum(BoundingBox, bounding_box_str) orelse return error.InvalidEnumTag;

    const material: ?[]const u8 = if (obj.get("material")) |m|
        if (m == .string) m.string else null
    else
        null;

    const harvest_tools: ?std.StringHashMap(bool) = if (obj.get("harvestTools")) |ht| blk: {
        if (ht != .object) return error.UnexpectedToken;
        const ht_obj = ht.object;
        var map = std.StringHashMap(bool).init(allocator);
        errdefer map.deinit();

        var iter = ht_obj.iterator();
        while (iter.next()) |entry| {
            const key = entry.key_ptr.*;
            const can_harvest = if (entry.value_ptr.* == .bool) entry.value_ptr.bool else false;
            if (can_harvest)
                try map.put(key, true);
        }

        break :blk map;
    } else null;

    const variations: ?[]BlockVariation = if (obj.get("variations")) |v| blk: {
        if (v != .array) return error.UnexpectedToken;
        const arr = v.array;
        var vars = try allocator.alloc(BlockVariation, arr.items.len);
        for (arr.items, 0..) |item, i| {
            vars[i] = try std.json.innerParseFromValue(BlockVariation, allocator, item, options);
        }
        break :blk vars;
    } else null;

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
    const drops: []DropItem = if (drops_val == .array) blk: {
        const arr = drops_val.array;
        var drop_arr = try allocator.alloc(DropItem, arr.items.len);
        for (arr.items, 0..) |item, i| {
            drop_arr[i] = try DropItem.jsonParseFromValue(allocator, item, options);
        }
        break :blk drop_arr;
    } else return error.UnexpectedToken;

    const transparent_val = try getRequired(obj, "transparent");
    const transparent = if (transparent_val == .bool) transparent_val.bool else return error.UnexpectedToken;

    const emit_light_val = try getRequired(obj, "emitLight");
    const emit_light: u8 = switch (emit_light_val) {
        .integer => |i| @intCast(i),
        else => return error.UnexpectedToken,
    };

    const filter_light_val = try getRequired(obj, "filterLight");
    const filter_light: u8 = switch (filter_light_val) {
        .integer => |i| @intCast(i),
        else => return error.UnexpectedToken,
    };

    const min_state_id: ?u32 = if (obj.get("minStateId")) |m|
        if (m == .integer) @intCast(m.integer) else null
    else
        null;

    const max_state_id: ?u32 = if (obj.get("maxStateId")) |m|
        if (m == .integer) @intCast(m.integer) else null
    else
        null;

    const default_state: ?u32 = if (obj.get("defaultState")) |d|
        if (d == .integer) @intCast(d.integer) else null
    else
        null;

    const resistance: ?f32 = if (obj.get("resistance")) |r| switch (r) {
        .integer => |i| @floatFromInt(i),
        .float => |f| @floatCast(f),
        .number_string => |ns| try std.fmt.parseFloat(f32, ns),
        .null => null,
        else => null,
    } else null;

    return Block{
        .id = id,
        .displayName = display_name,
        .name = name,
        .hardness = hardness,
        .stackSize = stack_size,
        .diggable = diggable,
        .boundingBox = bounding_box,
        .material = material,
        .harvestTools = harvest_tools,
        .variations = variations,
        .states = states,
        .drops = drops,
        .transparent = transparent,
        .emitLight = emit_light,
        .filterLight = filter_light,
        .minStateId = min_state_id,
        .maxStateId = max_state_id,
        .defaultState = default_state,
        .resistance = resistance,
    };
}

pub fn deinit(self: *Block, allocator: std.mem.Allocator) void {
    if (self.variations) |vars| {
        allocator.free(vars);
    }

    if (self.states) |sts| {
        allocator.free(sts);
    }

    for (self.drops) |drop| {
        DropItem.deinit(&drop, allocator);
    }

    if (self.harvestTools) |ht| {
        ht.deinit();
    }
}
