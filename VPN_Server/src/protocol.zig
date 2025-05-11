// const std = @import("std");

// pub const Packet = struct {
//     client_id: u32,
//     payload: []const u8,
//
//     pub fn parser(buf: []const u8) !Packet {
//         if (buf.len < 4) return error.InvalidPacket;
//
//         const client_id = std.mem.readInt(u32, buf[0..4], .big);
//         const payload = buf[4..];
//
//         return Packet{
//             .client_id = client_id,
//             .payload = payload,
//         };
//     }
//     pub fn encode(self: Packet, allocator: std.mem.Allocator) ![]u8 {
//         const len_of_buf = 4 + self.payload.len;
//         const buf = try allocator.alloc(u8, len_of_buf);
//
//         std.mem.WriteInt(u32, buf[0..4], self.client_id, .Big);
//         std.mem.copyForwards(u8, buf[4..], self.payload);
//         return buf;
//     }
// };
