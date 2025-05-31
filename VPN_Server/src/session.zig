// here will be the session that will log cilents and disconnect them when wanted
// it will store the unique client id or something else in clients list(hashmao or something else )
// and when they disconnect it will just remove them from the list
// or not client id but ip and port it would be better and cooler
const std = @import("std");
const packet = @import("protocol.zig").Packet;
const errors = @import("errors.zig");
const errs = errors.session_errors;
const server = @import("server.zig").Socket;
const Crypto = @import("crypto.zig").Crypto;


pub const ServerData = struct {
    ip: []const u8,
    port: u16,
};


const ClientKey = struct {
    ip: []const u8,

    pub fn hash(self: @This()) u64 {
        return std.hash.Wyhash.hash(0, self.ip);
    }

    pub fn eql(self: @This(), other: @This()) bool {
        return std.mem.eql(u8, self.ip, other.ip);
    }

    pub const Context = struct {
        pub fn hash(self: @This(), key: ClientKey) u64 {
            _ = self;
            return key.hash();
        }
        pub fn eql(self: @This(), a: ClientKey, b: ClientKey) bool {
            _ = self;
            return a.eql(b);
        }
    };
};

const ClientData = struct {
    port: u16,
};

pub const Session = struct {
    allocator: std.mem.Allocator,
    clients: std.HashMap(ClientKey, ClientData, ClientKey.Context, std.hash_map.default_max_load_percentage),

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator) !Session {
        return Session{
            .allocator = allocator,
            .clients = std.HashMap(ClientKey, ClientData, ClientKey.Context, std.hash_map.default_max_load_percentage).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.clients.deinit();
    }

    pub fn log_client(self: *Self, crypto: *Crypto, socket: *server, data: packet, permission: bool) !void {
        
        const client_key = ClientKey{
            .ip = data.ip,
        };

        const client_data = ClientData{
            .port = data.port,
        };
    
       if (permission) {
        const server_data = ServerData{
            .ip = "84.234.123.160",
            .port = 55555,
        };

        
        try server.send(socket, crypto, server_data, &self.allocator);
        }
        
        try self.clients.put(client_key, client_data);
        std.debug.print("Client: {s} logged\n", .{data.ip});
    }

    pub fn logout_client(self: *Self, ip: []const u8) !void {
        
        std.debug.print("the ip: {s}\n", .{ip});
        const client_key = ClientKey{
            .ip = ip,
        };

        if (!self.clients.remove(client_key)) {
            std.debug.print("Couldn't disconnect\n", .{});
            return errs.CantLogOut;
        }
        std.debug.print("client: {s}, logged out\n", .{client_key.ip});
    }

    pub fn check_clients(self: *Self) !void {
        var iterator = self.clients.iterator();
        std.debug.print("List of connected Clients: \n", .{});
        while (iterator.next()) |entry| {
            const client = entry.value_ptr.*;
            std.debug.print("Client connected at: {}\n", .{client.port});
        }
    }
};





test "init session test" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    
    // Test initialization
    var session = try Session.init(arena.allocator());
    defer session.deinit();
    
    // Verify clients map is empty
    try std.testing.expectEqual(@as(usize, 0), session.clients.count());
}

test "log in session test" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var session = try Session.init(arena.allocator());
    defer session.deinit();

    var test_input: [40]u8 = undefined;
    for (test_input[0..12], 0..) |_, i| test_input[i] = @intCast(i);
    for (test_input[12..24], 0..) |_, i| test_input[12 + i] = 0xAA;
    for (test_input[24..], 0..) |_, i| test_input[24 + i] = 0xBB;

    var crypto = Crypto.init(&test_input);
    var sock = try server.init("127.0.0.1", 0);
    defer sock.deinit();

    const test_packet = packet{
        .ip = "192.168.1.1",
        .port = 12345,
    };

    try session.log_client(&crypto, &sock, test_packet, false);
    try std.testing.expectEqual(@as(usize, 1), session.clients.count());
}

test "log out session test" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    
    var session = try Session.init(arena.allocator());
    defer session.deinit();
    
    const test_ip = "192.168.1.1";
    try session.clients.put(
        ClientKey{.ip = test_ip},
        ClientData{.port = 12345}
    );
    
    try session.logout_client(test_ip);
    
    try std.testing.expectEqual(@as(usize, 0), session.clients.count());
}
