const std = @import("std");

const enums = @import("enums.zig");

const OpenerType = enums.OpenerType;

const WindowOpener = @This();

type: OpenerType,
id: u32,
