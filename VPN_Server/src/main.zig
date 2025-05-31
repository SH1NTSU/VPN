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
    const diss_msg = "DISCONNECT";

    while (true) {
        const received_len = try socket.listen(&buffer);
        std.debug.print("received_len: {d}\n", .{received_len}); 
        const received = buffer[0..received_len];

        if (received_len >= diss_msg.len and std.mem.eql(u8, received[(received_len - diss_msg.len)..], diss_msg)) {
            std.debug.print("Disconnect message received\n", .{});
            const ip = received[0..(received_len - diss_msg.len)];
            try session_.logout_client(ip);
            session.check_clients(&session_) catch |err| {
                std.debug.print("Client check failed: {}\n", .{err});
            };
            continue;
        }

        // Ensure received data is long enough for encryption/decryption
        if (received_len < 28) {
            continue;
        }

        var crypto_ = crypto.init(received[0..received.len]);

        const packet = crypto.decrypt(&crypto_) catch |err| {
            std.debug.print("Decryption failed: {}\n", .{err});
            continue;
        };

        try session.log_client(&session_,&crypto_, &socket,  packet, true);

        session.check_clients(&session_) catch |err| {
            std.debug.print("Client check failed: {}\n", .{err});
        };
    }
}

