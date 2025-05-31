const std = @import("std");
const aead = std.crypto.aead.aes_gcm.Aes256Gcm;
const protocol = @import("protocol.zig");
const Packet = protocol.Packet;
const Session = @import("session.zig").ServerData;
const testing = std.testing;

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
        defer allocator.free(c);

        var tag = self.tag;
        _ = aead.encrypt(c, &tag, encoded, self.add, self.nonce, self.key);
        
        // Duplicate if you really need to (but prefer Approach 1)
        const encrypted = try allocator.dupe(u8, c);
    
    return encrypted;

    }
};

test "init method test " {
    var test_input: [40]u8 = undefined;
    
    for (test_input[0..12], 0..) |_, i| test_input[i] = @intCast(i);
    for (test_input[12..24], 0..) |_, i| test_input[12 + i] = 0xAA;
    for (test_input[24..], 0..) |_, i| test_input[24 + i] = 0xBB;

    var crypto = Crypto.init(&test_input);

    try testing.expectEqualSlices(u8, crypto.nonce[0..], test_input[0..12]);
    try testing.expectEqualSlices(u8, crypto.tag[0..], test_input[24..]);
    try testing.expectEqualSlices(u8, crypto.ciphertext, test_input[12..24]);

    try testing.expectEqual(crypto.add.len, "auth_data".len);
}

test "decrypt method test " {
    var test_input: [40]u8 = undefined;
    
    for (test_input[0..12], 0..) |_, i| test_input[i] = @intCast(i);
    for (test_input[12..24], 0..) |_, i| test_input[12 + i] = 0xAA;
    for (test_input[24..], 0..) |_, i| test_input[24 + i] = 0xBB;

    var crypto = Crypto.init(&test_input);

    const decrypted = Crypto.decrypt(&crypto);
    const info = @typeInfo(@TypeOf(decrypted));
    try testing.expectEqualStrings(@tagName(info), "error_union");
}


test "crypto method test " {
    
    var test_input: [40]u8 = undefined;
    
    for (test_input[0..12], 0..) |_, i| test_input[i] = @intCast(i);
    for (test_input[12..24], 0..) |_, i| test_input[12 + i] = 0xAA;
    for (test_input[24..], 0..) |_, i| test_input[24 + i] = 0xBB;

    var crypto = Crypto.init(&test_input);
    var test_allocator = testing.allocator;
    const test_payload = Session{
        .ip = "84.234.123.160",
        .port = 55555,
    };

    const encrypted = try Crypto.encrypt(&crypto, test_payload,&test_allocator);
    defer test_allocator.free(encrypted);
    
    try testing.expect(encrypted.len > 0);

}
