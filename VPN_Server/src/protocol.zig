const std = @import("std");
const errors = @import("errors.zig");
const err = errors.parser_errors;
const Session = @import("session.zig").ServerData;
const testing = std.testing;


pub const Packet = struct {
    port: u16,
    ip: []const u8,
    const Self = @This();
    pub fn parser(payload: []const u8) !Packet {
        if (payload.len < 4) return err.WrongStructure;

        const last_colon = std.mem.lastIndexOfScalar(u8, payload, ':') orelse {
            return err.WrongStructure; // No ':' found
        };

        const ip = payload[0..last_colon];

        const port_str = payload[last_colon + 1..];

        const port = std.fmt.parseInt(u16, port_str, 10) catch {
            std.log.err("Invalid port: {s}", .{port_str});
            return err.InvalidPort;
        };

        return Packet{
            .port = port,
            .ip = ip,
        };
    }


    pub fn encode(payload: Session, allocator: *std.mem.Allocator) ![]const u8 {
        const max_port_digits = 5; // u16 max: 65535 (5 digits)
        const encoded_len = payload.ip.len + 1 + max_port_digits; // "IP:PORT"

        const encoded = try allocator.alloc(u8, encoded_len);
        errdefer allocator.free(encoded);

        const written = try std.fmt.bufPrint(
            encoded,
            "{s}:{}",
            .{ payload.ip, payload.port },
        );

        return encoded[0..written.len];
    }
};







test "parser test" {
    const test_payload = "192.168.1.1:8080";
        
    const packet = try Packet.parser(test_payload);
        
    try testing.expectEqualStrings(packet.ip, "192.168.1.1");    
    try testing.expectEqual(packet.port, 8080);
}




test "encoding test" {
    
    var test_allocator = testing.allocator;

    const test_payload = Session{
        .ip = "84.234.123.160",
        .port = 55555,
    };
    
    const encoded = try Packet.encode(test_payload, &test_allocator);
    defer test_allocator.free(encoded);  
    
    try testing.expect(encoded.len > 0);

}   
