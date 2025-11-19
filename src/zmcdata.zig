const std = @import("std");
const config = @import("config");
const schema = @import("schema/schema.zig");
const enums = @import("enums.zig");
const McType = enums.McType;

const Zmcdata = @This();

allocator: std.mem.Allocator,
mc_type: McType,
path: []const u8 = config.mcdatapath,
data_paths: std.StringHashMap([]const u8),

pub fn init(allocator: std.mem.Allocator, mc_type: McType) Zmcdata {
    return .{
        .allocator = allocator,
        .mc_type = mc_type,
        .path = config.mcdatapath,
        .data_paths = std.StringHashMap([]const u8).init(allocator),
    };
}

pub fn deinit(self: *Zmcdata) void {
    var it = self.data_paths.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
        self.allocator.free(entry.value_ptr.*);
    }
    self.data_paths.deinit();
}

pub fn load(self: *Zmcdata, version: []const u8) !void {
    self.clearPaths();

    const paths_file = try std.fs.path.join(self.allocator, &.{ self.path, "dataPaths.json" });
    defer self.allocator.free(paths_file);

    const file = try std.fs.openFileAbsolute(paths_file, .{});
    defer file.close();

    const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
    defer self.allocator.free(content);

    const parsed = try std.json.parseFromSlice(std.json.Value, self.allocator, content, .{});
    defer parsed.deinit();

    const type_obj = parsed.value.object.get(self.mc_type.toString()) orelse return error.McTypeNotFound;
    const version_obj = type_obj.object.get(version) orelse return error.VersionNotFound;

    var it = version_obj.object.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* != .string) continue;

        const filename = try std.fmt.allocPrint(self.allocator, "{s}.json", .{entry.key_ptr.*});
        defer self.allocator.free(filename);

        const full_path = try std.fs.path.join(self.allocator, &.{ self.path, entry.value_ptr.string, filename });
        const key_dupe = try self.allocator.dupe(u8, entry.key_ptr.*);

        const gop = try self.data_paths.getOrPut(key_dupe);
        if (gop.found_existing) {
            self.allocator.free(key_dupe);
            self.allocator.free(gop.value_ptr.*);
        }
        gop.value_ptr.* = full_path;
    }
}

fn clearPaths(self: *Zmcdata) void {
    var it = self.data_paths.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
        self.allocator.free(entry.value_ptr.*);
    }
    self.data_paths.clearRetainingCapacity();
}

pub fn ParsedWithBuf(comptime T: type) type {
    return struct {
        parsed: std.json.Parsed(T),
        buf: ?[]u8,

        pub fn deinit(self: *ParsedWithBuf(T), allocator: std.mem.Allocator) void {
            self.parsed.deinit();
            if (self.buf) |b| allocator.free(b);
            self.buf = null;
        }
    };
}

pub fn get(self: *Zmcdata, comptime T: type, dataname: []const u8) !ParsedWithBuf(T) {
    const data_path = self.data_paths.get(dataname) orelse blk: {
        std.log.warn("Key '{s}' not found, using common path", .{dataname});
        const filename = try std.fmt.allocPrint(self.allocator, "{s}.json", .{dataname});
        defer self.allocator.free(filename);
        break :blk try std.fs.path.join(self.allocator, &.{ self.path, self.mc_type.toString(), "common", filename });
    };
    const owns_path = self.data_paths.get(dataname) == null;
    defer if (owns_path) self.allocator.free(data_path);

    const file = try std.fs.openFileAbsolute(data_path, .{ .mode = .read_only });
    defer file.close();

    var buf: [1024]u8 = undefined;
    var reader = file.reader(&buf);
    var writer: std.Io.Writer.Allocating = .init(self.allocator);
    defer writer.deinit();

    _ = try reader.interface.stream(&writer.writer, .unlimited);
    const content = try writer.toOwnedSlice();
    const data = try std.json.parseFromSlice(T, self.allocator, content, .{});

    return .{ .parsed = data, .buf = content };
}

test "Load Version Data Paths" {
    var zmcdata = Zmcdata.init(std.testing.allocator, .pc);
    defer zmcdata.deinit();
    try zmcdata.load("1.14");

    try std.testing.expectStringEndsWith(zmcdata.data_paths.get("blocks").?, "data/pc/1.14.4/blocks.json");
    try std.testing.expectStringEndsWith(zmcdata.data_paths.get("items").?, "data/pc/1.14/items.json");
}

test "Get Data For Bedrock Recipes" {
    var zmcdata = Zmcdata.init(std.testing.allocator, .bedrock);
    defer zmcdata.deinit();
    try zmcdata.load("1.21.93");

    var parsed = try zmcdata.get(schema.Recipes, "recipes");
    defer parsed.deinit(zmcdata.allocator);
}

test "Get Data For PC Blocks" {
    var zmcdata = Zmcdata.init(std.testing.allocator, .pc);
    defer zmcdata.deinit();
    try zmcdata.load("1.18");

    var parsed = try zmcdata.get(schema.Blocks, "blocks");
    defer parsed.deinit(zmcdata.allocator);
}

test "Get Block Harvest Tools" {
    var zmcdata = Zmcdata.init(std.testing.allocator, .pc);
    defer zmcdata.deinit();
    try zmcdata.load("1.21");

    var blocks = try zmcdata.get(schema.Blocks, "blocks");
    defer blocks.deinit(zmcdata.allocator);

    var items = try zmcdata.get(schema.Items, "items");
    defer items.deinit(zmcdata.allocator);

    const item_id: []const u8 = "825"; // stone_pickaxe

    for (blocks.parsed.value) |block| {
        if (std.mem.eql(u8, block.name, "stone")) {
            try std.testing.expect(block.id == 1);
            try std.testing.expectEqualStrings("stone", block.name);
            const ht = block.harvestTools orelse continue;
            try std.testing.expect(ht.get(item_id) orelse false);
            try std.testing.expectEqualStrings("stone_pickaxe", items.parsed.value[try std.fmt.parseInt(u16, item_id, 10)].name);
            break;
        }
    }
}
