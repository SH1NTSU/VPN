const std = @import("std");
const posix = std.posix;
const net = std.net;
const testing = std.testing;

pub fn main() !void {
    var socket = try Socket.init("127.0.0.1", 55555);
    defer socket.deinit();

    try socket.bind();

    var buffer: [1024]u8 = undefined;
    _ = try socket.listen(&buffer);
}

const Socket = struct {
    address: net.Address,
    socket: posix.socket_t,

    pub fn init(ip: []const u8, port: u16) !Socket {
        const addr = try net.Address.parseIp(ip, port);
        const sock = try posix.socket(posix.AF.INET, posix.SOCK.DGRAM, posix.IPPROTO.UDP);
        return Socket{ .address = addr, .socket = sock };
    }

    pub fn deinit(self: *Socket) void {
        _ = posix.close(self.socket);
    }

    pub fn bind(self: *Socket) !void {
        try posix.bind(self.socket, &self.address.any, self.address.getOsSockLen());
    }

    pub fn listen(self: *Socket, buffer: *[1024]u8) !usize {
        var sender_addr: net.Address = undefined;
        var addr_len: posix.socklen_t = @sizeOf(net.Address);
        return try posix.recvfrom(self.socket, buffer, 0, &sender_addr.any, &addr_len);
    }
};

fn serverThread(server: *Socket, received_msg: *[1024]u8, received_len: *usize) void {
    received_len.* = server.listen(received_msg) catch 0;
}

test "UDP server receives message correctly" {
    var server = try Socket.init("127.0.0.1", 55555);
    defer server.deinit();
    try server.bind();

    var received_msg: [1024]u8 = undefined;
    var received_len: usize = 0;

    var server_thread = try std.Thread.spawn(.{}, serverThread, .{ &server, &received_msg, &received_len });
    defer server_thread.join();

    const client_socket = try posix.socket(posix.AF.INET, posix.SOCK.DGRAM, posix.IPPROTO.UDP);
    defer posix.close(client_socket);

    var server_addr = try net.Address.parseIp("127.0.0.1", 55555);
    const test_message = "Hello, Server!";
    _ = try posix.sendto(client_socket, test_message, 0, &server_addr.any, server_addr.getOsSockLen());

    std.time.sleep(100_000_000);

    try testing.expect(received_len == test_message.len);
    try testing.expect(std.mem.eql(u8, received_msg[0..received_len], test_message));
}
