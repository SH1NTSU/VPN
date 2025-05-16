const std = @import("std");
const crypto = @import("crypto.zig").Crypto;
const server = @import("server.zig");
const session = @import("session.zig").Session;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var socket = try server.Socket.init("0.0.0.0", 55555);
    defer socket.deinit();
    try socket.bind();
    std.debug.print("Server listening on 0.0.0.0:55555\n", .{});

    var session_ = try session.init(gpa.allocator());
    defer session_.deinit();
    
    var buffer: [1024]u8 = undefined;

    while (true) {
        const received_len = try socket.listen(&buffer);

        var crypto_ = crypto.init(buffer[0..received_len]);

        const  packet = crypto.decrypt(&crypto_) catch |err| {
            std.debug.print("Decryption failed: {}\n", .{err});
            continue;
        };

        try session.log_client(&crypto_, &socket, &session_, packet);

        session.check_clients(&session_) catch |err| {
            std.debug.print("Client check failed: {}\n", .{err});
        };
    }
}

