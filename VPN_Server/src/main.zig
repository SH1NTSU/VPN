const std = @import("std");
const crypto = @import("crypto.zig");
const server = @import("server.zig");
const testing = std.testing;

pub fn main() !void {
    var socket = try server.Socket.init("0.0.0.0", 55555);
    defer socket.deinit();
    try socket.bind();
    var buffer: [1024]u8 = undefined;
    
    while (true) {
        const received_len = try socket.listen(&buffer);
        if (received_len < 32){ std.debug.print("Packet too short: len={}\n", .{received_len}); break;}
        const packet = try crypto.decrypt(buffer[0..received_len]);
        std.debug.print("Decrypted message: {s} {d} \n", .{packet.IP, packet.PORT});
    }
}

