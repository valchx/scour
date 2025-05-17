const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const Utils = @import("../utils.zig");
const theme = @import("../theme.zig");

const EntryList = @import("./entry_list.zig");

const Self = @This();

cwd_absolute_path: []const u8,
temp_cwd_absolute_path: ?std.ArrayList(u8) = null,
is_focused: bool = false,
cursor_utf_byte_position: usize,
_allocator: std.mem.Allocator,
entry_list: *EntryList,

pub fn init(
    allocator: std.mem.Allocator,
    cwd_absolute_path: []const u8,
    entry_list: *EntryList,
) Self {
    return Self{
        ._allocator = allocator,
        .cwd_absolute_path = cwd_absolute_path,
        .cursor_utf_byte_position = @intCast(cwd_absolute_path.len),
        .entry_list = entry_list,
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
        self.entry_list.*.changeDir(temp_cwd_absolute_path.items) catch {};

        temp_cwd_absolute_path.*.deinit();
        self.temp_cwd_absolute_path = null;
    }
}

fn renderInteractiveInput(self: *Self) !void {
    var cursor_color = theme.cwdInput.text;
    cursor_color[3] = if (@mod(@as(i32, @intFromFloat(rl.getTime())), 2) == 0) 0 else 255;

    const absolute_path = &self.temp_cwd_absolute_path.?;
    const cursor_utf_byte_position = &self.cursor_utf_byte_position;

    try Utils.text.handleKeyboardInputs(
        absolute_path,
        cursor_utf_byte_position,
        Utils.Callback(*Self){
            .ctx = self,
            .call = onBlur,
        },
    );

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
