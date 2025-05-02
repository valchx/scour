const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const Utils = @import("../utils.zig");
const theme = @import("../theme.zig");

const EntryList = @import("./entry_list.zig");

const Self = @This();

const KeyOrChar = union(enum) {
    char_code: []const u8,
    key_code: rl.KeyboardKey,
};

cwd_absolute_path: []const u8,
temp_cwd_absolute_path: ?std.ArrayList(u8) = null,
is_focused: bool = false,
cursor_utf_byte_position: usize,
_allocator: std.mem.Allocator,
entryList: *EntryList,
key_debounce: ?struct {
    key: KeyOrChar,
    debounce: struct {
        first_press_ms: i32,
        last_repeat: ?i32,
    },
} = null,

pub fn init(
    allocator: std.mem.Allocator,
    cwd_absolute_path: []const u8,
    entryList: *EntryList,
) Self {
    return Self{
        ._allocator = allocator,
        .cwd_absolute_path = cwd_absolute_path,
        .cursor_utf_byte_position = @intCast(cwd_absolute_path.len),
        .entryList = entryList,
    };
}

pub fn deinit(self: Self) void {
    if (self.temp_cwd_absolute_path) |temp_cwd_absolute_path| {
        temp_cwd_absolute_path.deinit();
    }
}

fn onFocus(self: *Self) !void {
    self.*.is_focused = true;

    if (self.temp_cwd_absolute_path) |*temp_cwd_absolute_path| {
        temp_cwd_absolute_path.*.deinit();
        self.temp_cwd_absolute_path = null;
    }

    self.*.temp_cwd_absolute_path = try std.ArrayList(u8).initCapacity(self._allocator, self.cwd_absolute_path.len);
    try self.temp_cwd_absolute_path.?.appendSlice(self.cwd_absolute_path);

    // TODO : Delect click position.
    self.*.cursor_utf_byte_position = self.cwd_absolute_path.len;
}

fn onBlur(self: *Self) !void {
    self.*.is_focused = false;

    if (self.temp_cwd_absolute_path) |*temp_cwd_absolute_path| {
        try self.entryList.*.changeDir(temp_cwd_absolute_path.items);

        temp_cwd_absolute_path.*.deinit();
        self.temp_cwd_absolute_path = null;
    }
}

fn handleKeyboardInput(
    self: *Self,
    key_or_char: KeyOrChar,
) !void {
    const absolute_path = &self.temp_cwd_absolute_path.?;
    const cursor_utf_byte_position = &self.cursor_utf_byte_position;

    switch (key_or_char) {
        .char_code => |char_code| {
            try absolute_path.*.appendSlice(char_code);
            cursor_utf_byte_position.* += char_code.len;
        },
        .key_code => |key| {
            if (key == .enter or key == .escape) {
                try self.onBlur();
            }

            if (key == .end) {
                cursor_utf_byte_position.* = absolute_path.items.len;
            }

            if (key == .home) {
                cursor_utf_byte_position.* = 0;
            }

            // Move cursor left
            if (key == .left and cursor_utf_byte_position.* > 0) {
                const slice_before = absolute_path.items[0..cursor_utf_byte_position.*];
                const last_char_len = Utils.unicode.getLastUnicodeCharByteLen(slice_before);
                if (last_char_len > 0) {
                    cursor_utf_byte_position.* -= last_char_len;
                }
            }

            // Move cursor right
            if (key == .right and cursor_utf_byte_position.* < absolute_path.items.len) {
                const slice_after = absolute_path.items[cursor_utf_byte_position.*..];
                const next_char_len = Utils.unicode.getFirstUnicodeCharByteLen(slice_after);
                if (next_char_len > 0) {
                    cursor_utf_byte_position.* += next_char_len;
                }
            }

            // Handle backspace
            if (key == .backspace and cursor_utf_byte_position.* > 0) {
                const slice_before = absolute_path.items[0..cursor_utf_byte_position.*];
                const last_char_len = Utils.unicode.getLastUnicodeCharByteLen(slice_before);
                if (last_char_len > 0) {
                    try absolute_path.resize(absolute_path.*.items.len - last_char_len);
                    cursor_utf_byte_position.* -= last_char_len;
                }
            }

            // Handle delete
            if (key == .delete and cursor_utf_byte_position.* < absolute_path.items.len) {
                const slice_after = absolute_path.items[cursor_utf_byte_position.*..];
                const next_char_len = Utils.unicode.getFirstUnicodeCharByteLen(slice_after);
                if (next_char_len > 0) {
                    try absolute_path.replaceRange(cursor_utf_byte_position.*, next_char_len, &[_]u8{});
                }
            }
        },
    }
}

fn renderInteractiveInput(self: *Self) !void {
    var cursor_color = theme.cwdInput.text;
    cursor_color[3] = if (@mod(@as(i32, @intFromFloat(rl.getTime())), 2) == 0) 0 else 255;

    const absolute_path = &self.temp_cwd_absolute_path.?;
    const cursor_utf_byte_position = &self.cursor_utf_byte_position;

    // Handle character input
    char_codes: while (true) {
        const char_code: u21 = @intCast(rl.getCharPressed());
        if (char_code == 0) {
            break :char_codes;
        }
        var char_code_buf: [4]u8 = undefined;
        const len = try std.unicode.utf8Encode(char_code, &char_code_buf);
        try self.handleKeyboardInput(.{ .char_code = char_code_buf[0..len] });
    }

    // Handle special keys
    special_keys: while (true) {
        const key = rl.getKeyPressed();
        if (key == .null) {
            break :special_keys;
        }

        try self.handleKeyboardInput(.{ .key_code = key });
    }

    const before_cursor = absolute_path.items[0..(if (absolute_path.items.len >= cursor_utf_byte_position.*) cursor_utf_byte_position.* else 0)];
    const after_cursor = absolute_path.items[(if (absolute_path.items.len >= cursor_utf_byte_position.*) cursor_utf_byte_position.* else 0)..];

    cl.text(before_cursor, cl.TextElementConfig{
        .font_size = 24,
        .color = theme.cwdInput.text,
    });

    // Cursor
    cl.text("|", cl.TextElementConfig{
        .font_size = 24,
        .color = cursor_color,
    });

    cl.text(after_cursor, cl.TextElementConfig{
        .font_size = 24,
        .color = theme.cwdInput.text,
    });
}

pub fn render(self: *Self) !void {
    const cwd_input_id = cl.ElementId.ID("cwd-input");
    cl.UI()(cl.ElementDeclaration{
        .id = cwd_input_id,
        .layout = .{
            .direction = .left_to_right,
            .sizing = .{ .h = .fit, .w = .grow },
            .padding = .all(8),
            .child_alignment = .{ .x = .left, .y = .center },
        },
        .background_color = theme.cwdInput.background,
    })({
        if (rl.isMouseButtonPressed(.left)) {
            if (cl.pointerOver(cwd_input_id)) {
                if (!self.is_focused) {
                    try self.*.onFocus();
                }
            } else {
                try self.*.onBlur();
            }
        }

        if (self.is_focused) {
            try self.renderInteractiveInput();
        } else {
            cl.text(self.cwd_absolute_path, cl.TextElementConfig{
                .font_size = 24,
                .color = theme.cwdInput.text,
            });
        }
    });
}
