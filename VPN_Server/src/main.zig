const std = @import("std");
const crypto = @import("crypto.zig");
const Cstruct = crypto.Crypto;
const server = @import("server.zig");
const testing = std.testing;

pub fn main() !void {
    var socket = try server.Socket.init("127.0.0.1", 55555);
    defer socket.deinit();

    try socket.bind();
    var buffer: [1024]u8 = undefined;
    while (true) {
        const received_len = try socket.listen(&buffer);
        if (received_len < 12 + 16 + 4) {
            std.debug.print("Packet too short: len={}\n", .{received_len});
            continue;
        }
        const decrypt = try Cstruct.decrypt(buffer[0..received_len]);
        defer std.heap.page_allocator.free(decrypt.payload);

        std.debug.print("Decrypted message: {s} \n", .{decrypt.payload});
    }
}

