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

pub fn Callback(
    comptime Context: type,
) type {
    return struct {
        ctx: Context,
        call: *const fn (ctx: Context) anyerror!void,

        pub fn invoke(self: @This()) !void {
            try self.call(self.ctx);
        }
    };
}

pub const text = struct {
    pub const KeyOrChar = union(enum) {
        char_code: []const u8,
        key_code: rl.KeyboardKey,
    };

    pub fn handleSingleKeyboardInput(
        key_or_char: KeyOrChar,
        buf: *std.ArrayList(u8),
        cursor_utf_byte_position: *usize,
        onBlur: anytype,
    ) !void {
        comptime {
            if (@TypeOf(onBlur) != Callback(@TypeOf(onBlur.ctx))) {
                @compileError("onBlur must be a BlurCallback");
            }
        }

        switch (key_or_char) {
            .char_code => |char_code| {
                try buf.*.appendSlice(char_code);
                cursor_utf_byte_position.* += char_code.len;
            },
            .key_code => |key| {
                if (key == .enter or key == .escape) {
                    try onBlur.invoke();
                }

                if (key == .end) {
                    cursor_utf_byte_position.* = buf.items.len;
                }

                if (key == .home) {
                    cursor_utf_byte_position.* = 0;
                }

                // Move cursor left
                if (key == .left and cursor_utf_byte_position.* > 0) {
                    const slice_before = buf.items[0..cursor_utf_byte_position.*];
                    const last_char_len = unicode.getLastUnicodeCharByteLen(slice_before);
                    if (last_char_len > 0) {
                        cursor_utf_byte_position.* -= last_char_len;
                    }
                }

                // Move cursor right
                if (key == .right and cursor_utf_byte_position.* < buf.items.len) {
                    const slice_after = buf.items[cursor_utf_byte_position.*..];
                    const next_char_len = unicode.getFirstUnicodeCharByteLen(slice_after);
                    if (next_char_len > 0) {
                        cursor_utf_byte_position.* += next_char_len;
                    }
                }

                // Handle backspace
                if (key == .backspace and cursor_utf_byte_position.* > 0) {
                    const slice_before = buf.items[0..cursor_utf_byte_position.*];
                    const last_char_len = unicode.getLastUnicodeCharByteLen(slice_before);
                    if (last_char_len > 0) {
                        try buf.resize(buf.*.items.len - last_char_len);
                        cursor_utf_byte_position.* -= last_char_len;
                    }
                }

                // Handle delete
                if (key == .delete and cursor_utf_byte_position.* < buf.items.len) {
                    const slice_after = buf.items[cursor_utf_byte_position.*..];
                    const next_char_len = unicode.getFirstUnicodeCharByteLen(slice_after);
                    if (next_char_len > 0) {
                        try buf.replaceRange(cursor_utf_byte_position.*, next_char_len, &[_]u8{});
                    }
                }
            },
        }
    }

    pub fn handleKeyboardInputs(
        buf: *std.ArrayList(u8),
        cursor_utf_byte_position: *usize,
        onBlur: anytype,
    ) !void {
        // Handle character input
        char_codes: while (true) {
            const char_code: u21 = @intCast(rl.getCharPressed());
            if (char_code == 0) {
                break :char_codes;
            }
            var char_code_buf: [4]u8 = undefined;
            const len = try std.unicode.utf8Encode(char_code, &char_code_buf);
            try handleSingleKeyboardInput(
                .{ .char_code = char_code_buf[0..len] },
                buf,
                cursor_utf_byte_position,
                onBlur,
            );
        }

        // Handle special keys
        special_keys: while (true) {
            const key = rl.getKeyPressed();
            if (key == .null) {
                break :special_keys;
            }

            try handleSingleKeyboardInput(
                .{ .key_code = key },
                buf,
                cursor_utf_byte_position,
                onBlur,
            );
        }
    }
};
