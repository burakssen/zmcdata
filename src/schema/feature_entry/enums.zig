const std = @import("std");

const VersionedValue = @import("versioned_value.zig");

pub const Versioning = union(enum) {
    single_version: []const u8,
    version_range: [2][]const u8,
    versioned_values: []VersionedValue,

    pub fn jsonParseFromObject(allocator: std.mem.Allocator, obj: std.json.ObjectMap, options: std.json.ParseOptions) !Versioning {
        if (obj.get("version")) |v| {
            if (v == .string) {
                return Versioning{ .single_version = v.string };
            }
        }

        if (obj.get("versions")) |v| {
            if (v != .array) return error.UnexpectedToken;
            const arr = v.array;
            if (arr.items.len != 2) return error.LengthMismatch;

            const min_ver = if (arr.items[0] == .string) arr.items[0].string else return error.UnexpectedToken;
            const max_ver = if (arr.items[1] == .string) arr.items[1].string else return error.UnexpectedToken;

            return Versioning{ .version_range = [2][]const u8{ min_ver, max_ver } };
        }

        if (obj.get("values")) |v| {
            if (v != .array) return error.UnexpectedToken;
            const arr = v.array;

            var vals = try allocator.alloc(VersionedValue, arr.items.len);
            for (arr.items, 0..) |item, i| {
                vals[i] = try VersionedValue.jsonParseFromValue(allocator, item, options);
            }

            return Versioning{ .versioned_values = vals };
        }

        return error.MissingField;
    }
};

pub const VersionValue = union(enum) {
    integer: i64,
    string: []const u8,

    pub fn jsonParseFromValue(_: std.mem.Allocator, source: std.json.Value, _: std.json.ParseOptions) !VersionValue {
        if (source == .integer) {
            return VersionValue{ .integer = source.integer };
        } else if (source == .string) {
            return VersionValue{ .string = source.string };
        } else {
            return error.UnexpectedToken;
        }
    }
};
