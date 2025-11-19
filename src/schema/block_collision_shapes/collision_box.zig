const std = @import("std");

const CollisionBox = @This();

coords: [6]f32,

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !CollisionBox {
    _ = allocator;
    _ = options;

    if (source != .array) return error.UnexpectedToken;
    const arr = source.array;

    if (arr.items.len != 6) return error.LengthMismatch;

    var coords: [6]f32 = undefined;
    for (arr.items, 0..) |item, i| {
        coords[i] = switch (item) {
            .integer => |int| @floatFromInt(int),
            .float => |f| @floatCast(f),
            .number_string => |ns| try std.fmt.parseFloat(f32, ns),
            else => return error.UnexpectedToken,
        };
    }

    return CollisionBox{ .coords = coords };
}
