const std = @import("std");

const enums = @import("enums.zig");
const FeatureVersioning = enums.FeatureVersioning;

const FeatureEntry = @This();

name: []const u8,
description: []const u8,
versioning: FeatureVersioning,

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !FeatureEntry {
    const json_value = try std.json.innerParse(std.json.Value, allocator, source, options);

    if (json_value != .object) return error.UnexpectedToken;
    const obj = json_value.object;

    const name_val = obj.get("name") orelse return error.MissingField;
    const name = if (name_val == .string) name_val.string else return error.UnexpectedToken;

    const description_val = obj.get("description") orelse return error.MissingField;
    const description = if (description_val == .string) description_val.string else return error.UnexpectedToken;

    const versioning = try FeatureVersioning.jsonParseFromObject(allocator, obj, options);

    return FeatureEntry{
        .name = name,
        .description = description,
        .versioning = versioning,
    };
}
