const std = @import("std");
const config = @import("config");
const schema = @import("schema/schema.zig");
const Zmcdata = @This();

pub const McType = enum {
    bedrock,
    pc,

    pub fn toString(self: McType) []const u8 {
        return switch (self) {
            .bedrock => "bedrock",
            .pc => "pc",
        };
    }
};

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
        std.debug.print("Warning: Key '{s}' not found.\n", .{dataname});

        const filename = try std.fmt.allocPrint(self.allocator, "{s}.json", .{dataname});
        defer self.allocator.free(filename);

        data_path = try std.fs.path.join(
            self.allocator,
            &.{ self.path, self.mc_type.toString(), "common", filename },
        );
        owns_path = true;

        std.debug.print("Using fallback path: {s}\n", .{data_path});
    }

    defer if (owns_path) {
        self.allocator.free(data_path);
    };

    std.debug.print("Data Path: {s}\n", .{data_path});

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
    var zmcdata = Zmcdata.init(std.testing.allocator, .pc);
    defer zmcdata.deinit();

    try zmcdata.load("1.21");
    const block_data = try zmcdata.get(schema.Blocks, "blocks");
    defer block_data.deinit();

    const biome_data = try zmcdata.get(schema.Biomes, "biomes");
    defer biome_data.deinit();

    const attribute_data = try zmcdata.get(schema.Attributes, "attributes");
    defer attribute_data.deinit();

    const block_collision_shape_data = try zmcdata.get(schema.BlockCollisionShapes, "blockCollisionShapes");
    defer block_collision_shape_data.deinit();

    // const map_j2b = try zmcdata.get(schema.BlockMapping, "blocksJ2B");
    // defer map_j2b.deinit();

    // const map_b2j = try zmcdata.get(schema.BlockMapping, "blocksB2J");
    // defer map_b2j.deinit();

    const commands_data = try zmcdata.get(schema.Commands, "commands");
    defer commands_data.deinit();

    for (commands_data.value.parsers) |parser| {
        if (parser.modifier) |modifier| {
            std.debug.print("Parser: {s}, Modifier: {any}\n", .{ parser.parser, modifier });
        }
    }

    const effects_data = try zmcdata.get(schema.Effects, "effects");
    defer effects_data.deinit();

    const enchantments_data = try zmcdata.get(schema.Enchantments, "enchantments");
    defer enchantments_data.deinit();

    const entities_data = try zmcdata.get(schema.Entities, "entities");
    defer entities_data.deinit();

    // const entity_loot_data = try zmcdata.get(schema.EntityLoot, "entityLoot");
    // defer entity_loot_data.deinit();

    const features_data = try zmcdata.get(schema.Features, "features");
    defer features_data.deinit();

    // const foods_data = try zmcdata.get(schema.Foods, "foods");
    // defer foods_data.deinit();

    const instruments_data = try zmcdata.get(schema.Instruments, "instruments");
    defer instruments_data.deinit();

    const items_data = try zmcdata.get(schema.Items, "items");
    defer items_data.deinit();

    const language_data = try zmcdata.get(schema.Language, "language");
    defer language_data.deinit();

    // const map_icons_data = try zmcdata.get(schema.MapIcons, "mapIcons");
    // defer map_icons_data.deinit();

    const materials_data = try zmcdata.get(schema.Materials, "materials");
    defer materials_data.deinit();

    // const particles_data = try zmcdata.get(schema.Particles, "particles");
    // defer particles_data.deinit();

    const protocol_versions_data = try zmcdata.get(schema.ProtocolVersions, "protocolVersions");
    defer protocol_versions_data.deinit();

    const recipes_data = try zmcdata.get(schema.Recipes, "recipes");
    defer recipes_data.deinit();

    // const sounds_data = try zmcdata.get(schema.Sounds, "sounds");
    // defer sounds_data.deinit();

    // const tints_data = try zmcdata.get(schema.Tints, "tints");
    // defer tints_data.deinit();

    // const version_data = try zmcdata.get(schema.Version, "version");
    // defer version_data.deinit();

    const windows_data = try zmcdata.get(schema.Windows, "windows");
    defer windows_data.deinit();
}
