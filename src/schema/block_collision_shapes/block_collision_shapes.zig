const std = @import("std");

const enums = @import("enums.zig");
const ShapeId = enums.ShapeId;

const CollisionBox = @import("collision_box.zig");

const BlockCollisionShapes = @This();

blocks: std.StringHashMap(ShapeId),
shapes: std.StringHashMap([]CollisionBox),

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !BlockCollisionShapes {
    const json_value = try std.json.innerParse(std.json.Value, allocator, source, options);

    if (json_value != .object) return error.UnexpectedToken;
    const obj = json_value.object;

    const blocks_val = obj.get("blocks") orelse return error.MissingField;
    if (blocks_val != .object) return error.UnexpectedToken;

    var blocks = std.StringHashMap(ShapeId).init(allocator);
    errdefer {
        var it = blocks.valueIterator();
        while (it.next()) |shape_id| {
            shape_id.deinit(allocator);
        }
        blocks.deinit();
    }

    var blocks_it = blocks_val.object.iterator();
    while (blocks_it.next()) |entry| {
        const shape_id = try ShapeId.jsonParseFromValue(allocator, entry.value_ptr.*, options);
        try blocks.put(entry.key_ptr.*, shape_id);
    }

    const shapes_val = obj.get("shapes") orelse return error.MissingField;
    if (shapes_val != .object) return error.UnexpectedToken;

    var shapes = std.StringHashMap([]CollisionBox).init(allocator);
    errdefer {
        var it = shapes.valueIterator();
        while (it.next()) |boxes| {
            allocator.free(boxes.*);
        }
        shapes.deinit();
    }

    var shapes_it = shapes_val.object.iterator();
    while (shapes_it.next()) |entry| {
        if (entry.value_ptr.* != .array) return error.UnexpectedToken;
        const arr = entry.value_ptr.array;

        var boxes = try allocator.alloc(CollisionBox, arr.items.len);
        for (arr.items, 0..) |item, i| {
            boxes[i] = try CollisionBox.jsonParseFromValue(allocator, item, options);
        }

        try shapes.put(entry.key_ptr.*, boxes);
    }

    return BlockCollisionShapes{
        .blocks = blocks,
        .shapes = shapes,
    };
}

pub fn deinit(self: *BlockCollisionShapes, allocator: std.mem.Allocator) void {
    var blocks_it = self.blocks.valueIterator();
    while (blocks_it.next()) |shape_id| {
        shape_id.deinit(allocator);
    }
    self.blocks.deinit();

    var shapes_it = self.shapes.valueIterator();
    while (shapes_it.next()) |boxes| {
        allocator.free(boxes.*);
    }
    self.shapes.deinit();
}
