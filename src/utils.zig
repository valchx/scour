const std = @import("std");
const rl = @import("raylib");
const renderer = @import("raylib_render_clay.zig");

pub fn loadFont(file_data: ?[]const u8, font_id: u16, font_size: i32) !void {
    renderer.raylib_fonts[font_id] = try rl.loadFontFromMemory(".ttf", file_data, font_size * 2, null);
    rl.setTextureFilter(renderer.raylib_fonts[font_id].?.texture, .bilinear);
}

pub fn loadImage(comptime path: [:0]const u8) !rl.Texture2D {
    const texture = try rl.loadTextureFromImage(try rl.loadImageFromMemory(@ptrCast(std.fs.path.extension(path)), @embedFile(path)));
    rl.setTextureFilter(texture, .bilinear);
    return texture;
}

pub const unicode = struct {
    pub fn getFirstUnicodeCharByteLen(buf: []const u8) usize {
        if (buf.len == 0) return 0;
        return std.unicode.utf8ByteSequenceLength(buf[0]) catch 0;
    }

    pub fn getLastUnicodeCharByteLen(buf: []const u8) usize {
        if (buf.len == 0) return 0;

        var i = buf.len;
        while (i > 0) : (i -= 1) {
            if (std.unicode.utf8ByteSequenceLength(buf[i - 1]) catch 0 == buf.len - (i - 1)) {
                return buf.len - (i - 1);
            }
        }
        return 0;
    }
};
