const std = @import("std");

pub const BoundingBox = enum {
    block,
    empty,
};

pub const DropItem = union(enum) {
    simple: u32,
    complex: ComplexDrop,

    const ComplexDrop = struct {
        minCount: ?f32 = null,
        maxCount: ?f32 = null,
        drop: DropReference,
    };

    const DropReference = union(enum) {
        id: u32,
        detailed: DetailedDrop,

        const DetailedDrop = struct {
            id: u32,
            metadata: u32,
        };
    };

    pub fn jsonParseFromValue(_: std.mem.Allocator, source: std.json.Value, _: std.json.ParseOptions) !DropItem {
        // Simple case: just an integer ID
        if (source == .integer) {
            return DropItem{ .simple = @intCast(source.integer) };
        }

        // Complex case: object with minCount, maxCount, drop
        if (source != .object) return error.UnexpectedToken;
        const obj = source.object;

        const min_count: ?f32 = if (obj.get("minCount")) |mc| switch (mc) {
            .integer => |i| @floatFromInt(i),
            .float => |f| @floatCast(f),
            .number_string => |ns| try std.fmt.parseFloat(f32, ns),
            else => null,
        } else null;

        const max_count: ?f32 = if (obj.get("maxCount")) |mc| switch (mc) {
            .integer => |i| @floatFromInt(i),
            .float => |f| @floatCast(f),
            .number_string => |ns| try std.fmt.parseFloat(f32, ns),
            else => null,
        } else null;

        const drop_val = obj.get("drop") orelse return error.MissingField;

        const drop: DropReference = blk: switch (drop_val) {
            .object => |dv| {
                const id_val = dv.get("id") orelse return error.MissingField;
                const id: u32 = if (id_val == .integer) @intCast(id_val.integer) else return error.UnexpectedToken;

                const metadata_val = dv.get("metadata") orelse return error.MissingField;
                const metadata: u32 = if (metadata_val == .integer) @intCast(metadata_val.integer) else return error.UnexpectedToken;

                break :blk DropReference{ .detailed = .{ .id = id, .metadata = metadata } };
            },
            .integer => |dv| DropReference{ .id = @intCast(dv) },
            else => return error.UnexpectedToken,
        };

        return DropItem{
            .complex = .{
                .minCount = min_count,
                .maxCount = max_count,
                .drop = drop,
            },
        };
    }
};
