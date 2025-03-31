const std = @import("std");
const posix = std.posix;
const net = std.net;

pub fn main() !void {
    var socket = try Socket.init("127.0.0.1", 55555);
    defer socket.deinit();

    try socket.bind();
    try socket.listen();
}

const Socket = struct {
    address: std.net.Address,
    socket: std.posix.socket_t,

    pub fn init(ip: []const u8, port: u16) !Socket {
        const addr = try std.net.Address.parseIp(ip, port);
        const sock = try std.posix.socket(std.posix.AF.INET, std.posix.SOCK.DGRAM, std.posix.IPPROTO.UDP);
        return Socket{ .address = addr, .socket = sock };
    }

    pub fn deinit(self: *Socket) void {
        std.posix.close(self.socket);
    }

    pub fn bind(self: *Socket) !void {
        try std.posix.bind(self.socket, &self.address.any, self.address.getOsSockLen());
    }

    pub fn listen(self: *Socket) !void {
        var buffer: [1024]u8 = undefined;
        while (true) {
            var sender_addr: std.net.Address = undefined;
            var addr_len: posix.socklen_t = @sizeOf(std.net.Address);
            var sender_buffer: [64]u8 = undefined;
            const len = try posix.recvfrom(self.socket, &buffer, 0, &sender_addr.any, &addr_len);
            const formatted_sender = try std.fmt.bufPrint(&sender_buffer, "{any}", .{sender_addr});
            std.debug.print("Received {d} bytes from {s}:{d}: {s}\n", .{
                len, formatted_sender, sender_addr.getPort(), buffer[0..len],
            });
        }
    }
};
