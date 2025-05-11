const std = @import("std");
const aead = std.crypto.aead.aes_gcm.Aes256Gcm;

pub const Crypto = struct {
    payload: []u8,




    pub fn decrypt(received_data: []const u8) !Crypto {
        const key: [32]u8 = "your-32-byte-secure-key-string!2".*;
        const ad: []const u8 = "auth_data"; // Must match Swift if used
        const allocator = std.heap.page_allocator;

        // Verify minimum length (nonce + minimum ciphertext + tag)
        if (received_data.len < 12 + 16) return error.PacketTooShort;

        const nonce = received_data[0..12].*;
        const ciphertext = received_data[12..received_data.len - 16];
        const tag = received_data[24..40].*;

        std.debug.print(
            "Received Nonce: {s} Ciphertext: {s} Tag: {s}\n",
            .{
                std.fmt.fmtSliceHexLower(&nonce),
                std.fmt.fmtSliceHexLower(ciphertext),
                std.fmt.fmtSliceHexLower(&tag),
            }
        );

        var decrypted = try allocator.alloc(u8, ciphertext.len);
        errdefer allocator.free(decrypted); 
        try aead.decrypt(
            decrypted,    
            ciphertext,   
            tag,         
            ad,          
            nonce,        
            key           
        );

        if (decrypted.len < 4) {
            allocator.free(decrypted);
            return error.InvalidPayload;
        }

        const payload = try allocator.dupe(u8, decrypted[0..]); 
        
        return Crypto{
            .payload = payload,
        };
    }
};
