const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var options = b.addOptions();
    options.addOption(
        []const u8,
        "integration_url",
        b.option([]const u8, "integration_url", "The URL to run the integration tests against") orelse "http://localhost:10061",
    );

    const module = b.addModule("refresh-api-zig", .{
        .root_source_file = b.path("src/api.zig"),
    });

    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_tests.root_module.addOptions("options", options);
    main_tests.root_module.addImport("api", module);

    b.getInstallStep().dependOn(&main_tests.step);

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    const install_docs = b.addInstallDirectory(.{
        .source_dir = main_tests.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "doc",
    });
    const install_docs_step = b.step("docs", "Generate and install the documentation");
    install_docs_step.dependOn(&install_docs.step);
}
