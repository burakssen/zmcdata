const std = @import("std");

const Material = @This();

tool_multipliers: std.StringHashMap(f32),

pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !Material {
    _ = options;

    if (source != .object) return error.UnexpectedToken;
    const obj = source.object;

    var tool_multipliers = std.StringHashMap(f32).init(allocator);
    errdefer tool_multipliers.deinit();

    var it = obj.iterator();
    while (it.next()) |entry| {
        const multiplier: f32 = switch (entry.value_ptr.*) {
            .integer => |i| @floatFromInt(i),
            .float => |f| @floatCast(f),
            .number_string => |ns| try std.fmt.parseFloat(f32, ns),
            else => return error.UnexpectedToken,
        };

        try tool_multipliers.put(entry.key_ptr.*, multiplier);
    }

    return Material{ .tool_multipliers = tool_multipliers };
}

pub fn deinit(self: *Material) void {
    self.tool_multipliers.deinit();
}
