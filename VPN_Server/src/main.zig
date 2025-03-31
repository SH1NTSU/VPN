const std = @import("std");
const net = std.net;
const crypto = std.crypto;

pub fn main() !void {
    const address = try net.Address.parseIp4("0.0.0.0", 51820);
    var server = net.StreamServer.init(.{ .reuse_address = true });
    try server.listen(address);

    std.log.info("VPN Server started on {}", .{address});

    while (true) {
        const connection = try server.accept();
        defer connection.stream.close();
        handleClient(connection.stream) catch |err| {
            std.log.err("Client error: {}", .{err});
        };
    }
}

fn handleClient(stream: net.Stream) !void {
    var buf: [1024]u8 = undefined;

    while (true) {
        const bytes_read = try stream.read(&buf);
        if (bytes_read == 0) break; // Connection closed

        const packet = buf[0..bytes_read];
        std.log.info("Received {} bytes", .{bytes_read});

        try stream.writeAll(packet);
    }
}
