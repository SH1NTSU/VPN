// here will be the session that will log cilents and disconnect them when wanted
// it will store the unique client id or something else in clients list(hashmao or something else )
// and when they disconnect it will just remove them from the list
// or not client id but ip and port it would be better and cooler
const std = @import("std");
const packet = @import("protocol.zig").Packet;
const errors = @import("errors.zig");
const errs = errors.session_errors;

const ClientKey = struct {
    ip: []const u8,
    port: u16,
};
const ClientData = struct {
    connected_at: i64, 
};

pub const Session = struct {
    allocator: std.mem.Allocator,
    clients: std.AutoHashMap(ClientKey, ClientData),
    

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator) !Session {
        return Session{
            .allocator = allocator,
            .clients = std.hash.autoHashStrat(ClientKey, ClientData, .Deep),
        };
    }

    pub fn deinit(self: *Self) void {
        self.clients.deinit();
    }

    pub fn log_client(self: *Self, data: packet) !void {
        const client_key = ClientKey{
            .ip = data.ip,
            .port = data.port,
        };

        const current_time = std.time.milliTimestamp();
        const client_data = ClientData{
            .connected_at = current_time,
        };

       self.clients.put(client_key, client_data) catch {
            std.log.err("Invalid data", .{});
            return errs.CantLogIn;
        }; 
        std.debug.print("Client: {any} logged", .{data.ip});

    }

    pub fn logout_client(self: *Self, data: packet) !void {
        const client_key = ClientKey{
            .ip = data.ip,
            .port = data.port,
        };
        self.clients.remove(client_key) catch {
            std.debug.print("Couldnt disconnect", .{});
            return errs.CantLogOut;
        };
        std.debug.print("client: {any}, loged out", .{client_key.ip});
    }

    pub fn check_clients(self: *Self) !void {
        var iterator = self.clients.iterator();
        std.debug.print("List of connected Clients: \n", .{});
        for(iterator.next()) |entry| {
            const client =  entry.value;
            std.debug.print("Client connected at: {any}", .{client.connection_time});
        }
    }

};
