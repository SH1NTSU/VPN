const std = @import("std");
const errors = @import("errors.zig");
const err = errors.parser_errors;

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

    pub fn encode(self: *Self, allocator: std.mem.Allocator) ![]u8 {
        const encoded = try allocator.alloc(u8, self.IP.len + 6); // 4 for PORT, 2 for ':'
        const writer = std.mem.writer(encoded);

        try writer.print("{}:{}", .{self.IP, self.PORT});
        return encoded[0..writer.written()];
    }
};

