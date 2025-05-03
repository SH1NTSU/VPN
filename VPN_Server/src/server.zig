const std = @import("std");
const posix = std.posix;
const net = std.net;
pub const Socket = struct {
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
