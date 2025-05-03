const std = @import("std");
const crypto = @import("crypto.zig")
const server = @import("server.zig");
const testing = std.testing;

pub fn main() !void {
    var socket = try server.Socket.init("127.0.0.1", 55555);
    defer socket.deinit();

    try socket.bind();

    var buffer: [1024]u8 = undefined;
    while (true) {
        const received_len = try socket.listen(&buffer);
        const data = buffer[0..received_len];

        const decrypted = try crypto.decrypt(key, data);
        std.debug.print("Received packet from client {}: {s}\n", .{ decrypted.client_id, decrypted.payload });
    }
}

// fn serverThread(server: *Socket, received_msg: *[1024]u8, received_len: *usize) void {
//     received_len.* = server.listen(received_msg) catch 0;

//     const data = received_msg[0..received_len.*];
//     const packet = protocol.Packet.parse(data) catch {
//         std.debug.print("Invalid packet received\n", .{});
//         return;
//     };

//     std.debug.print("Client ID: {}, Payload: {s}\n", .{ packet.client_id, packet.payload });
// }

// test "UDP server receives message correctly" {
//     var server = try Socket.init("127.0.0.1", 55555);
//     defer server.deinit();
//     try server.bind();

//     var received_msg: [1024]u8 = undefined;
//     var received_len: usize = 0;

//     var server_thread = try std.Thread.spawn(.{}, serverThread, .{ &server, &received_msg, &received_len });
//     defer server_thread.join();

//     const client_socket = try posix.socket(posix.AF.INET, posix.SOCK.DGRAM, posix.IPPROTO.UDP);
//     defer posix.close(client_socket);

//     var server_addr = try net.Address.parseIp("127.0.0.1", 55555);
//     const test_message = "Hello, Server!";
//     _ = try posix.sendto(client_socket, test_message, 0, &server_addr.any, server_addr.getOsSockLen());

//     std.time.sleep(100_000_000);

//     try testing.expect(received_len == test_message.len);
//     try testing.expect(std.mem.eql(u8, received_msg[0..received_len], test_message));
// }
