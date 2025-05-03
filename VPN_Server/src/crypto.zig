const std = @import("std");
const crypto = std.crypto;
const aes = crypto.core.aes;
const protocol = @import("protocol.zig");
const Packet = protocol.Packet;

const allocator = std.mem.Allocator;
pub const Crypto = struct {
    client_id: u32,
    payload: []u8,
    // pub fn encrypt(key: [32]u8, payload: []u8, client_id: u32 ) ![]u8 {
    //     var iv: [16]u8 = undefined;
    //     crypto.random.bytes(&iv); // Generate random IV

    //     // Pack client_id + payload into a buffer
    //     const plaintext = self.pack(client_id, payload);
    //     // Pad plaintext to 16-byte blocks (PKCS#7)
    //     const padded_len = ((plaintext.items.len + 15) / 16) * 16;
    //     var padded = try allocator.alloc(u8, padded_len);
    //     std.mem.copy(u8, padded, plaintext.items);

    //     // Apply PKCS#7 padding
    //     const pad_byte = @intCast(u8, padded_len - plaintext.items.len);
    //     @memset(padded[plaintext.items.len..], pad_byte);

    //     // Encrypt
    //     var ciphertext = try allocator.alloc(u8, padded_len);
    //     aes.Aes256.initEncrypt(key).encryptCbc(ciphertext, padded, iv);

    //     // Return IV + ciphertext (needed for decryption)
    //     var result = try allocator.alloc(u8, iv.len + ciphertext.len);
    //     std.mem.copy(u8, result[0..16], iv);
    //     std.mem.copy(u8, result[16..], ciphertext);
    //     return result;
    // }

    // pub fn pack(client_id: u32, payload: []u8) ![]u8 {
    //     var plaintext = try std.ArrayList(u8).init(allocator);
    //     defer plaintext.deinit();

    //     try plaintext.writer().writeIntLittle(u32, client_id);
    //     try plaintext.writer().writeAll(payload);
    //     return plaintext;
    // }
    pub fn decrypt(key: [32]u8, data: []u8) !Crypto {
        if (data.len < 16) return error.InvalidPacket; // Must have IV

        const iv = data[0..16];
        const ciphertext = data[16..];

        var plaintext = try allocator.alloc(u8, ciphertext.len);
        defer allocator.free(plaintext);

        aes.Aes256.initDecrypt(key).decryptCbc(plaintext, ciphertext, iv);

        // Remove PKCS#7 padding
        const pad_byte = plaintext[plaintext.len - 1];
        if (pad_byte > 16) return error.InvalidPadding;
        const unpadded_len = plaintext.len - pad_byte;

        // Extract client_id (first 4 bytes) and payload
        const client_id = std.mem.readIntLittle(u32, plaintext[0..4]);
        const payload = plaintext[4..unpadded_len];

        return Crypto{
            .client_id = client_id,
            .payload = payload,
        };
    }
};
