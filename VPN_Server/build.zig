const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    const exe = b.addExecutable(.{
        .name = "vpn-server",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    const protocol = b.addModule("protocol", .{
        .root_source_file = .{ .path = "src/protocol.zig"}
    });

    const session = b.addModule("session", .{
        .root_source_file = .{ .path = "src/session.zig"}
    });    
    const crypto = b.addModule("crypto", .{
        .root_source_file = .{ .path = "src/crypto.zig"}
    });    
    exe.root_module.addImport(("protocol"), protocol );
    exe.root_module.addImport(("crypto"), crypto );
    exe.root_module.addImport(("session"), session );
    b.installArtifact(exe);
    
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    const run_step = b.step("run", "Run the server");
    run_step.dependOn(&run_cmd.step);
}

