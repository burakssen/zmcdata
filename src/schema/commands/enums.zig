const std = @import("std");

const Parser = @import("parser.zig");

pub const NodeType = enum {
    root,
    literal,
    argument,

    pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !NodeType {
        const str = try std.json.innerParse([]const u8, allocator, source, options);
        return std.meta.stringToEnum(NodeType, str) orelse error.InvalidEnumTag;
    }
};

pub const CommandNode = union(enum) {
    root: RootNode,
    literal: LiteralNode,
    argument: ArgumentNode,

    pub const RootNode = struct {
        name: []const u8,
        executable: bool,
        redirects: [][]const u8,
        children: []CommandNode,
    };

    pub const LiteralNode = struct {
        name: []const u8,
        executable: bool,
        redirects: [][]const u8,
        children: []CommandNode,
    };

    pub const ArgumentNode = struct {
        name: []const u8,
        executable: bool,
        redirects: [][]const u8,
        children: []CommandNode,
        parser: ?Parser,
    };

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !CommandNode {
        if (source != .object) return error.UnexpectedToken;
        const obj = source.object;

        const type_val = obj.get("type") orelse return error.MissingField;
        const type_str = if (type_val == .string) type_val.string else return error.UnexpectedToken;

        const name_val = obj.get("name") orelse return error.MissingField;
        const name = if (name_val == .string) name_val.string else return error.UnexpectedToken;

        const executable_val = obj.get("executable") orelse return error.MissingField;
        const executable = if (executable_val == .bool) executable_val.bool else return error.UnexpectedToken;

        const redirects_val = obj.get("redirects") orelse return error.MissingField;
        const redirects: [][]const u8 = if (redirects_val == .array) blk: {
            const arr = redirects_val.array;
            var redir_arr = try allocator.alloc([]const u8, arr.items.len);
            for (arr.items, 0..) |item, i| {
                redir_arr[i] = if (item == .string) item.string else return error.UnexpectedToken;
            }
            break :blk redir_arr;
        } else return error.UnexpectedToken;

        const children_val = obj.get("children") orelse return error.MissingField;
        const children: []CommandNode = if (children_val == .array) blk: {
            const arr = children_val.array;
            var child_arr = try allocator.alloc(CommandNode, arr.items.len);
            for (arr.items, 0..) |item, i| {
                child_arr[i] = try CommandNode.jsonParseFromValue(allocator, item, options);
            }
            break :blk child_arr;
        } else return error.UnexpectedToken;

        if (std.mem.eql(u8, type_str, "root")) {
            return CommandNode{
                .root = .{
                    .name = name,
                    .executable = executable,
                    .redirects = redirects,
                    .children = children,
                },
            };
        } else if (std.mem.eql(u8, type_str, "literal")) {
            return CommandNode{
                .literal = .{
                    .name = name,
                    .executable = executable,
                    .redirects = redirects,
                    .children = children,
                },
            };
        } else if (std.mem.eql(u8, type_str, "argument")) {
            const parser: ?Parser = if (obj.get("parser")) |p|
                try Parser.jsonParseFromValue(allocator, p, options)
            else
                null;

            return CommandNode{
                .argument = .{
                    .name = name,
                    .executable = executable,
                    .redirects = redirects,
                    .children = children,
                    .parser = parser,
                },
            };
        } else {
            return error.InvalidEnumTag;
        }
    }
};

pub const Modifier = union(enum) {
    type_amount: TypeAmountModifier,
    registry: RegistryModifier,
    min_max_integer: MinMaxModifierInteger,
    min_max_float: MinMaxModifierFloat,

    pub const TypeAmountModifier = struct {
        type: ?[]const u8 = null,
        amount: ?[]const u8 = null,
    };

    pub const RegistryModifier = struct {
        registry: []const u8,
    };

    pub const MinMaxModifierInteger = struct {
        min: ?i64 = null,
        max: ?i64 = null,
    };

    pub const MinMaxModifierFloat = struct {
        min: ?f64 = null,
        max: ?f64 = null,
    };

    pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !Modifier {
        const value = try std.json.innerParse(std.json.Value, allocator, source, options);
        return jsonParseFromValue(allocator, value, options);
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, source: std.json.Value, _: std.json.ParseOptions) !Modifier {
        if (source != .object) return error.UnexpectedToken;
        const obj = source.object;

        if (obj.get("registry")) |v| return Modifier{
            .registry = .{ .registry = if (v == .string) v.string else return error.UnexpectedToken },
        };

        const type_val = obj.get("type");
        const amount_val = obj.get("amount");
        if (type_val != null or amount_val != null) {
            return Modifier{ .type_amount = .{
                .type = if (type_val) |v| (if (v == .string) v.string else return error.UnexpectedToken) else null,
                .amount = if (amount_val) |v| (if (v == .string) v.string else return error.UnexpectedToken) else null,
            } };
        }

        const min_v = obj.get("min");
        const max_v = obj.get("max");
        if (min_v != null or max_v != null) {
            const is_float = (min_v != null and min_v.? == .float) or (max_v != null and max_v.? == .float);

            if (is_float) {
                return Modifier{
                    .min_max_float = .{
                        .min = if (min_v) |v| switch (v) {
                            .float => |f| f,
                            .integer => |i| @floatFromInt(i),
                            else => return error.UnexpectedToken,
                        } else null,
                        .max = if (max_v) |v| switch (v) {
                            .float => |f| f,
                            .integer => |i| @floatFromInt(i),
                            else => return error.UnexpectedToken,
                        } else null,
                    },
                };
            }

            return Modifier{
                .min_max_integer = .{
                    .min = if (min_v) |v| (if (v == .integer) v.integer else return error.UnexpectedToken) else null,
                    .max = if (max_v) |v| (if (v == .integer) v.integer else return error.UnexpectedToken) else null,
                },
            };
        }

        return error.InvalidEnumTag;
    }
};
