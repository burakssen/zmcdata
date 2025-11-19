const std = @import("std");

pub const ShapeId = union(enum) {
    single: u32,
    multiple: []u32,

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !ShapeId {
        _ = options;

        // Single shape id (number)
        if (source == .integer) {
            return ShapeId{ .single = @intCast(source.integer) };
        }

        // Multiple shape ids (array)
        if (source == .array) {
            const arr = source.array;
            if (arr.items.len == 0) return error.LengthMismatch;

            var ids = try allocator.alloc(u32, arr.items.len);
            for (arr.items, 0..) |item, i| {
                ids[i] = switch (item) {
                    .integer => |int| @intCast(int),
                    else => return error.UnexpectedToken,
                };
            }
            return ShapeId{ .multiple = ids };
        }

        return error.UnexpectedToken;
    }

    pub fn deinit(self: ShapeId, allocator: std.mem.Allocator) void {
        switch (self) {
            .multiple => |ids| allocator.free(ids),
            .single => {},
        }
    }
};
