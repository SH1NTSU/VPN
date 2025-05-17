const std = @import("std");
const aead = std.crypto.aead.aes_gcm.Aes256Gcm;
const protocol = @import("protocol.zig");
const Packet = protocol.Packet;
const Session = @import("session.zig").ServerData;

pub const Crypto = struct {
    key: [32]u8,
    add: []const u8,
    tag: [16]u8,
    nonce: [12]u8,
    ciphertext: []const u8,
    
    pub fn init(received_data: []const u8) Crypto { 
        
        const key: [32]u8 = "your-32-byte-secure-key-string!2".*;
        const ad: []const u8 = "auth_data"; // Must match Swift if used
        
        const nonce = received_data[0..12].*;
        const ciphertext = received_data[12..received_data.len - 16];
       
        const tag_start = received_data.len - 16;
        var tag: [16]u8 = undefined;
        std.mem.copyBackwards(u8, &tag, received_data[tag_start..]); 
        
        return Crypto{
            .key = key, 
            .add = ad,
            .tag = tag,
            .nonce = nonce,
            .ciphertext = ciphertext,
        };


    }
    pub fn decrypt(self: *Crypto) !Packet   {
        
        const allocator = std.heap.page_allocator;


        var decrypted = try allocator.alloc(u8, self.ciphertext.len);
        errdefer allocator.free(decrypted); 
        try aead.decrypt(
            decrypted,    
            self.ciphertext,   
            self.tag,         
            self.add,          
            self.nonce,        
            self.key,           
        );

        if (decrypted.len < 4) {
            allocator.free(decrypted);
            return error.InvalidPayload;
        }

        const payload = try allocator.dupe(u8, decrypted[0..]);  
        const packet = protocol.Packet.parser(payload);
        std.debug.print("decrypted succedfully!\n", .{});
        return packet;
    }

    pub fn encrypt(self: *Crypto, payload: Session, allocator: *std.mem.Allocator) ![]const u8 {

        const encoded = try Packet.encode(payload, allocator);
        defer allocator.free(encoded);

        const c = try allocator.alloc(u8, encoded.len);
        errdefer allocator.free(c);

        var tag = self.tag;
        _ = aead.encrypt(c, &tag, encoded, self.add, self.nonce, self.key);
        
        const encrypted = try allocator.dupe(u8, c);
        return encrypted;
        }
};


