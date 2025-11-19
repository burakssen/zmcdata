const std = @import("std");

const VersionSpecificValue = @import("version_specific_value.zig");

pub const FeatureVersioning = union(enum) {
    single_version: []const u8,
    version_range: [2][]const u8,
    versioned_values: []VersionSpecificValue,

    pub fn jsonParseFromObject(allocator: std.mem.Allocator, obj: std.json.ObjectMap, options: std.json.ParseOptions) !FeatureVersioning {
        // Check for single version
        if (obj.get("version")) |v| {
            if (v == .string) {
                return FeatureVersioning{ .single_version = v.string };
            }
        }

        // Check for version range
        if (obj.get("versions")) |v| {
            if (v != .array) return error.UnexpectedToken;
            const arr = v.array;
            if (arr.items.len != 2) return error.LengthMismatch;

            const min_ver = if (arr.items[0] == .string) arr.items[0].string else return error.UnexpectedToken;
            const max_ver = if (arr.items[1] == .string) arr.items[1].string else return error.UnexpectedToken;

            return FeatureVersioning{ .version_range = [2][]const u8{ min_ver, max_ver } };
        }

        // Check for versioned values
        if (obj.get("values")) |v| {
            if (v != .array) return error.UnexpectedToken;
            const arr = v.array;

            var vals = try allocator.alloc(VersionSpecificValue, arr.items.len);
            for (arr.items, 0..) |item, i| {
                vals[i] = try VersionSpecificValue.jsonParseFromValue(allocator, item, options);
            }

            return FeatureVersioning{ .versioned_values = vals };
        }

        return error.MissingField;
    }
};
