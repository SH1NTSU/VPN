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

    pub fn log_client(crypto: *Crypto, socket: *server, self: *Self, data: packet) !void {
        
        const client_key = ClientKey{
            .ip = data.ip,
        };

        const client_data = ClientData{
            .port = data.port,
        };
    
        
        const server_data = ServerData{
            .ip = "84.234.123.160",
            .port = 55555,
        };

        
        try server.send(socket, crypto, server_data, &self.allocator);
        
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
