const std = @import("std");

const Slot = @import("slot.zig");
const WindowOpener = @import("window_opener.zig");

const Window = @This();

id: []const u8,
name: []const u8,
slots: ?[]Slot = null,
properties: ?[][]const u8 = null,
openedWith: ?[]WindowOpener = null,
