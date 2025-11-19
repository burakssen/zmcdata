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
    var it = self.data_paths.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
        self.allocator.free(entry.value_ptr.*);
    }
    self.data_paths.clearRetainingCapacity();

    const dataPathsFilePath = try std.fs.path.join(self.allocator, &.{ self.path, "dataPaths.json" });
    defer self.allocator.free(dataPathsFilePath);

    const dataPathsFile = std.fs.openFileAbsolute(dataPathsFilePath, .{}) catch return error.DataPathsFileNotFound;
    defer dataPathsFile.close();

    const file_content = try dataPathsFile.readToEndAlloc(self.allocator, 1024 * 1024);
    defer self.allocator.free(file_content);

    const parsed = try std.json.parseFromSlice(std.json.Value, self.allocator, file_content, .{});
    defer parsed.deinit();

    const type_obj = parsed.value.object.get(self.mc_type.toString()) orelse return error.McTypeNotFound;
    const version_obj = type_obj.object.get(version) orelse return error.VersionNotFound;

    var it2 = version_obj.object.iterator();
    while (it2.next()) |entry| {
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

pub fn get(self: *Zmcdata, comptime T: type, dataname: []const u8) !std.json.Parsed(T) {

    // Determine data_path and whether we own it (need to free it).
    var data_path: []const u8 = undefined;
    var owns_path: bool = false;

    const maybe = self.data_paths.get(dataname);
    if (maybe) |p| {
        data_path = p;
    } else {
        std.log.warn("Key '{s}' not found.", .{dataname});

        const filename = try std.fmt.allocPrint(self.allocator, "{s}.json", .{dataname});
        defer self.allocator.free(filename);

        data_path = try std.fs.path.join(
            self.allocator,
            &.{ self.path, self.mc_type.toString(), "common", filename },
        );
        owns_path = true;

        std.log.warn("Using common path: {s}", .{data_path});
    }

    defer if (owns_path) {
        self.allocator.free(data_path);
    };

    var file = try std.fs.openFileAbsolute(data_path, .{ .mode = .read_only });
    defer file.close();

    var file_buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&file_buffer);
    var file_writer: std.Io.Writer.Allocating = .init(self.allocator);
    defer file_writer.deinit();

    _ = try file_reader.interface.stream(&file_writer.writer, .unlimited);

    const content = try file_writer.toOwnedSlice();
    defer self.allocator.free(content);

    const data = try std.json.parseFromSlice(T, self.allocator, content, .{});

    return data;
}

test "Load Version Data Paths" {
    var zmcdata = Zmcdata.init(std.testing.allocator, .pc);
    defer zmcdata.deinit();

    try zmcdata.load("1.14");

    const blocks_path = zmcdata.data_paths.get("blocks").?;
    const items_path = zmcdata.data_paths.get("items").?;

    try std.testing.expectStringEndsWith(blocks_path, "data/pc/1.14.4/blocks.json");
    try std.testing.expectStringEndsWith(items_path, "data/pc/1.14/items.json");
}

test "Get Data" {
    var zmcdata = Zmcdata.init(std.testing.allocator, .bedrock);
    defer zmcdata.deinit();

    try zmcdata.load("1.21.93");

    const recipes = try zmcdata.get(schema.Recipes, "recipes");
    defer recipes.deinit();
}
