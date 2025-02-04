const std = @import("std");

const package_name = "static-buf";
const package_path = "src/lib.zig";

pub fn build(builder: *std.Build) void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    const lib = builder.addStaticLibrary(.{
        .name = package_name,
        .root_source_file = builder.path(package_path),
        .target = target,
        .optimize = optimize,
    });

    const lib_module = builder.addModule(package_name, .{
        .root_source_file = builder.path(package_path),
        .imports = &.{},
    });

    builder.installArtifact(lib);

    const tests = builder.addTest(.{
        .root_source_file = builder.path("tests/buf.zig"),
        .target = target,
        .optimize = optimize,
    });

    tests.root_module.addImport(package_name, lib_module);

    const run_tests = builder.addRunArtifact(tests);
    const test_step = builder.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
