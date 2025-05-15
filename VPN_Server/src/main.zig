const std = @import("std");
const crypto = @import("crypto.zig");
const server = @import("server.zig");
const testing = std.testing;
const session = @import("session.zig").Session;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();


    var socket = try server.Socket.init("0.0.0.0", 55555);
    try socket.bind();


    var session_ = try  session.init(gpa.allocator());

    defer session_.deinit();
    
    var buffer: [1024]u8 = undefined;
    while (true) {

    const received_len = try socket.listen(&buffer);
    
    if (received_len < 32){ 
        std.debug.print("Packet too short: len={}\n", .{received_len});
    
    }

    const packet = try crypto.decrypt(buffer[0..received_len]);
    

    

    try session.log_client(&session_, packet);
    try session.check_clients(&session_);

    }



}

