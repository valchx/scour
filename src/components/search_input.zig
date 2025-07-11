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

search_buf: ?std.ArrayList(u8) = null,
is_focused: bool = false,
cursor_utf_byte_position: usize,
_allocator: std.mem.Allocator,
entry_list: *EntryList,

pub fn init(
    allocator: std.mem.Allocator,
    entry_list: *EntryList,
) Self {
    const search_buf = std.ArrayList(u8).init(allocator);
    return Self{
        ._allocator = allocator,
        .search_buf = search_buf,
        .cursor_utf_byte_position = @intCast(search_buf.len),
        .entry_list = entry_list,
    };
}

pub fn deinit(self: Self) void {
    if (self.search_buf) |search_buf| {
        search_buf.deinit();
    }
}

fn onFocus(self: *Self) !void {
    self.*.is_focused = true;

    // TODO : Delect click position.
    self.*.cursor_utf_byte_position = self.search_buf.len;
}

fn onBlur(self: *Self) !void {
    self.*.is_focused = false;

    if (self.search_buf) |*search_buf| {
        self.entry_list.*.changeDir(search_buf.items) catch {};

        search_buf.*.deinit();
        self.search_buf = null;
    }
}

fn renderInteractiveInput(self: *Self) !void {
    var cursor_color = theme.cwdInput.text;
    cursor_color[3] = if (@mod(@as(i32, @intFromFloat(rl.getTime())), 2) == 0) 0 else 255;

    const buf = &self.search_buf.?;
    const cursor_utf_byte_position = &self.cursor_utf_byte_position;

    const blur_callback = Utils.Callback(*Self){
        .ctx = self,
        .call = onBlur,
    };

    try Utils.text.handleKeyboardInputs(
        buf,
        cursor_utf_byte_position,
        blur_callback,
    );

    const before_cursor = buf.items[0..cursor_utf_byte_position.*];
    const after_cursor = buf.items[cursor_utf_byte_position.*..];

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
    const cwd_input_id = cl.ElementId.ID("search-input");
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
        }
    });
}
