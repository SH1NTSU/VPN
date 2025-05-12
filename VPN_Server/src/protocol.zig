 const std = @import("std");

 pub const Packet = struct {
     PORT: u16,
     IP: []const u8,

     pub fn parser(payload: []const u8) !Packet {
         if (payload.len < 4) return error.InvalidPacket;

        const last_colon = std.mem.lastIndexOfScalar(u8, payload, ':') orelse {
            return error.InvalidFormat; // No ':' found
        };
    
       const ip = payload[0..last_colon];
        
        const port_str = payload[last_colon + 1 ..];

        const port = std.fmt.parseInt(u16, port_str, 10) catch |err| {
            std.log.err("Invalid port: {s}", .{port_str});
            return err;
        };
         return Packet{
                .PORT = port,
                .IP = ip,
         };
     }
     pub fn encode(self: Packet, allocator: std.mem.Allocator) ![]u8 {
         const len_of_buf = 4 + self.payload.len;
         const buf = try allocator.alloc(u8, len_of_buf);

         std.mem.WriteInt(u32, buf[0..4], self.client_id, .Big);
         std.mem.copyForwards(u8, buf[4..], self.payload);
         return buf;
     }
 };
