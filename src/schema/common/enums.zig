const std = @import("std");

pub const PropertyType = enum {
    @"enum",
    bool,
    int,
    direction,
};

pub const PropertyValue = union(enum) {
    string: []const u8,
    boolean: bool,
    integer: i32,

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !PropertyValue {
        _ = allocator;
        _ = options;

        return switch (source) {
            .string => |s| PropertyValue{ .string = s },
            .bool => |b| PropertyValue{ .boolean = b },
            .integer => |i| PropertyValue{ .integer = @intCast(i) },
            .number_string => |ns| PropertyValue{ .integer = try std.fmt.parseInt(i32, ns, 10) },
            else => error.UnexpectedToken,
        };
    }
};
