const std = @import("std");

const BlockMapping = @This();

map: std.StringHashMap([]const u8),

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !BlockMapping {
    _ = options;

    var map = std.StringHashMap([]const u8).init(allocator);
    errdefer map.deinit();

    // Ensure we are starting an object
    if (.object_begin != try source.next()) return error.UnexpectedToken;

    while (true) {
        const token = try source.next();
        switch (token) {
            .object_end => break,
            .string => |key_slice| {
                // Duplicate the key into the arena
                const key = try allocator.dupe(u8, key_slice);

                // Get the value (expecting a string for these specific files)
                const val_token = try source.next();
                const val_slice = switch (val_token) {
                    .string => |s| s,
                    else => return error.UnexpectedToken,
                };
                const val = try allocator.dupe(u8, val_slice);

                try map.put(key, val);
            },
            // If we encounter anything else in the key position, it's an error for this schema
            else => return error.UnexpectedToken,
        }
    }

    return BlockMapping{ .map = map };
}

pub fn deinit(self: *BlockMapping) void {
    self.map.deinit();
}
