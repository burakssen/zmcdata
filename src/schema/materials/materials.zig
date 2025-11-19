const std = @import("std");

const Material = @import("material.zig");

const Materials = @This();

materials: std.StringHashMap(Material),

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !Materials {
    const json_value = try std.json.innerParse(std.json.Value, allocator, source, options);

    if (json_value != .object) return error.UnexpectedToken;
    const obj = json_value.object;

    var materials = std.StringHashMap(Material).init(allocator);
    errdefer {
        var it = materials.valueIterator();
        while (it.next()) |material| {
            material.deinit();
        }
        materials.deinit();
    }

    var it = obj.iterator();
    while (it.next()) |entry| {
        const material = try Material.jsonParseFromValue(allocator, entry.value_ptr.*, options);
        try materials.put(entry.key_ptr.*, material);
    }

    return Materials{ .materials = materials };
}

pub fn deinit(self: *Materials, allocator: std.mem.Allocator) void {
    _ = allocator;
    var it = self.materials.valueIterator();
    while (it.next()) |material| {
        material.deinit();
    }
    self.materials.deinit();
}
