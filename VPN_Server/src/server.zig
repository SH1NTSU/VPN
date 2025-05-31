const std = @import("std");
const posix = std.posix;
const net = std.net;
const protocol = @import("protocol.zig");
const Crypto = @import("crypto.zig").Crypto;
const Session = @import("session.zig").ServerData;
const testing = std.testing;

pub const Socket = struct {
    address: net.Address,
    socket: posix.socket_t,

    const Self = @This();

    pub fn init(ip: []const u8, port: u16) !Socket {
        const addr = try net.Address.parseIp(ip, port);
        const sock = try posix.socket(posix.AF.INET, posix.SOCK.DGRAM, posix.IPPROTO.UDP);
        return Socket{ .address = addr, .socket = sock };
    }

    pub fn deinit(self: *Socket) void {
        _ = posix.close(self.socket);
        std.debug.print("server is closed!\n", .{});
    }

    pub fn bind(self: *Socket) !void {
        try posix.bind(self.socket, &self.address.any, self.address.getOsSockLen());
        std.debug.print("binding successfully!\n", .{});
    }

    pub fn listen(self: *Socket, buffer: *[1024]u8) !usize {
        var sender_addr: net.Address = undefined;
        var addr_len: posix.socklen_t = @sizeOf(net.Address);
        return try posix.recvfrom(self.socket, buffer, 0, &sender_addr.any, &addr_len);
    }

    pub fn send(self: *Socket, crypto: *Crypto, data: Session, allocator: *std.mem.Allocator) !void {
        const encrypted = try crypto.encrypt(data, allocator);
        defer allocator.free(encrypted); 

        _ = try std.posix.sendto(
            self.socket,
            encrypted,
            0,
            &self.address.any, 
            self.address.getOsSockLen()
        );
        std.debug.print("network address sent successfully!\n", .{});
    }    
};




test "init test" {
    const test_ip: []const u8 = "127.0.0.1";
    const test_port: u16 = 55555;
    
    const socket_union = try Socket.init(test_ip, test_port);

    const info = @typeInfo(@TypeOf(socket_union));

    try testing.expectEqualStrings(@tagName(info), "struct");
    
}



// to test listen function y need to send on the given ip and port the udp message



// test "listen test" { 
//     const test_ip: []const u8 = "127.0.0.1";
//     const test_port: u16 = 55555;
//     
//     var socket_union = try Socket.init(test_ip, test_port);
//     
//     var buffer: [1024]u8 = undefined;
//
//     const received = try Socket.listen(&socket_union, &buffer);
//
//
//     try testing.expect(received > 0);
//
//
// }


test "send test" {
     
    const test_ip: []const u8 = "127.0.0.1";
    const test_port: u16 = 55555;
    
    var socket_union = try Socket.init(test_ip, test_port);
    
    var test_input: [40]u8 = undefined;
    
    for (test_input[0..12], 0..) |_, i| test_input[i] = @intCast(i);
    for (test_input[12..24], 0..) |_, i| test_input[12 + i] = 0xAA;
    for (test_input[24..], 0..) |_, i| test_input[24 + i] = 0xBB;

    var crypto = Crypto.init(&test_input);
    var test_allocator = testing.allocator;
    const test_payload = Session{
        .ip = "84.234.123.160",
        .port = 55555,
    };

    try Socket.send(&socket_union, &crypto, test_payload, &test_allocator);

}





