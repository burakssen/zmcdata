const std = @import("std");

const Language = @This();

translations: std.StringHashMap([]const u8),

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !Language {
    const json_value = try std.json.innerParse(std.json.Value, allocator, source, options);

    if (json_value != .object) return error.UnexpectedToken;
    const obj = json_value.object;

    var translations = std.StringHashMap([]const u8).init(allocator);
    errdefer translations.deinit();

    var it = obj.iterator();
    while (it.next()) |entry| {
        const value = if (entry.value_ptr.* == .string)
            entry.value_ptr.string
        else
            return error.UnexpectedToken;

        try translations.put(entry.key_ptr.*, value);
    }

    return Language{ .translations = translations };
}

pub fn deinit(self: *Language) void {
    self.translations.deinit();
}
