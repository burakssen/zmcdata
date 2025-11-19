const std = @import("std");

const CostEquation = @import("cost_equation.zig");

const Enchantment = @This();

id: u32,
name: []const u8,
displayName: []const u8,
maxLevel: u8,
minCost: CostEquation,
maxCost: CostEquation,
treasureOnly: bool,
curse: bool,
exclude: [][]const u8,
category: []const u8,
weight: u8,
tradeable: bool,
discoverable: bool,
