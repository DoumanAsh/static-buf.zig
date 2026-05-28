const std = @import("std");

const package_name = "static-buf";
const package_path = "src/lib.zig";

pub fn build(builder: *std.Build) void {
    const target = builder.standardTargetOptions(.{});

    const lib_module = builder.addModule(package_name, .{
        .target = target,
        .root_source_file = builder.path(package_path),
        .imports = &.{},
    });
    const lib = builder.addLibrary(.{
        .name = package_name,
        .linkage = std.builtin.LinkMode.static,
        .root_module = lib_module
    });

    builder.installArtifact(lib);

    const tests = builder.addTest(.{
        .root_module = builder.createModule(.{
            .target = target,
            .root_source_file = builder.path("tests/buf.zig"),
        }),
    });

    tests.root_module.addImport(package_name, lib_module);

    const run_tests = builder.addRunArtifact(tests);
    const test_step = builder.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
