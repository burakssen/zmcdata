const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const minecraft_data_dep = b.dependency("minecraft-data", .{});

    // 1. Create an Options Step
    const build_options = b.addOptions();

    build_options.addOptionPath("mcdatapath", minecraft_data_dep.path("data"));

    const lib_mod = b.addModule("zmcdata", .{
        .root_source_file = b.path("src/zmcdata.zig"),
        .target = target,
        .optimize = optimize,
    });

    // 3. Attach the options to your library module
    // This allows your code to do: const config = @import("config");
    lib_mod.addOptions("config", build_options);

    const lib = b.addLibrary(.{
        .name = "zmcdata",
        .linkage = .static,
        .root_module = lib_mod,
    });

    b.installArtifact(lib);

    // --- REMOVED install_data logic ---

    const lib_tests = b.addTest(.{
        .name = "zmcdata-tests",
        .root_module = lib_mod,
    });

    const run_tests = b.addRunArtifact(lib_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
