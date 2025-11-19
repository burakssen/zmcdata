const std = @import("std");

const BlockItemDrop = @This();

item: []const u8,
metadata: ?u8 = null,
dropChance: f32,
stackSizeRange: []?i64,
blockAge: ?f32 = null,
silkTouch: ?bool = null,
noSilkTouch: ?bool = null,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !BlockItemDrop {
    _ = options;
    if (source != .object) return error.UnexpectedToken;
    const obj = source.object;

    const getRequired = struct {
        fn call(object: std.json.ObjectMap, comptime field: []const u8) !std.json.Value {
            return object.get(field) orelse return error.MissingField;
        }
    }.call;

    const item_val = try getRequired(obj, "item");
    const item = if (item_val == .string) item_val.string else return error.UnexpectedToken;

    const metadata: ?u8 = if (obj.get("metadata")) |m|
        if (m == .integer) @intCast(m.integer) else null
    else
        null;

    const drop_chance_val = try getRequired(obj, "dropChance");
    const drop_chance: f32 = switch (drop_chance_val) {
        .integer => |i| @floatFromInt(i),
        .float => |f| @floatCast(f),
        .number_string => |ns| try std.fmt.parseFloat(f32, ns),
        else => return error.UnexpectedToken,
    };

    const stack_size_range_val = try getRequired(obj, "stackSizeRange");
    const stack_size_range: []?i64 = if (stack_size_range_val == .array) blk: {
        const arr = stack_size_range_val.array;
        // FIX: Allocate `?i32` (optional int), not `i32`
        const range = try allocator.alloc(?i64, arr.items.len);

        for (arr.items, 0..) |_item_val, i| {
            range[i] = if (_item_val == .null)
                null
            else
                _item_val.integer;
        }
        break :blk range;
    } else return error.UnexpectedToken;

    const block_age: ?f32 = if (obj.get("blockAge")) |ba| switch (ba) {
        .integer => |i| @floatFromInt(i),
        .float => |f| @floatCast(f),
        .number_string => |ns| try std.fmt.parseFloat(f32, ns),
        else => null,
    } else null;

    const silk_touch: ?bool = if (obj.get("silkTouch")) |st|
        if (st == .bool) st.bool else null
    else
        null;

    const no_silk_touch: ?bool = if (obj.get("noSilkTouch")) |nst|
        if (nst == .bool) nst.bool else null
    else
        null;

    return BlockItemDrop{
        .item = item,
        .metadata = metadata,
        .dropChance = drop_chance,
        .stackSizeRange = stack_size_range,
        .blockAge = block_age,
        .silkTouch = silk_touch,
        .noSilkTouch = no_silk_touch,
    };
}
