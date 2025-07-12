const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const Utils = @import("../utils.zig");
const theme = @import("../theme.zig");

const Self = @This();

source_buf: ?[]const u8,
edit_buf: std.ArrayList(u8),
is_focused: bool = false,
cursor_utf_byte_position: ?usize,
_allocator: std.mem.Allocator,
id_suffix: []const u8,

ptr: *anyopaque,
vtable: *const VTable,

const VTable = struct {
    /// Called when the input is focused
    on_focus_callback: ?*const fn (*anyopaque) void,

    /// Called when the input is blurred/unfocused
    on_blur_callback: ?*const fn (*anyopaque, buf: []const u8) anyerror!void,
};

pub fn init(
    allocator: std.mem.Allocator,
    ptr: *anyopaque,
    vtable: *const VTable,
    id_suffix: []const u8,
    source_buf: ?[]const u8,
) Self {
    return Self{
        ._allocator = allocator,
        .ptr = ptr,
        .vtable = vtable,
        .id_suffix = id_suffix,
        .source_buf = source_buf,
        .cursor_utf_byte_position = 0,
        .edit_buf = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: Self) void {
    self.edit_buf.deinit();
}

fn onFocus(self: *Self) !void {
    self.*.is_focused = true;

    // We need to 'follow' the source_buf
    if (self.source_buf) |source_buf| {
        self.*.edit_buf.deinit();
        self.*.edit_buf = try std.ArrayList(u8).initCapacity(self._allocator, source_buf.len);
        try self.edit_buf.appendSlice(source_buf);
    }

    // TODO : Delect click position.
    // For now, just put the cursor at the end.
    self.*.cursor_utf_byte_position = self.edit_buf.items.len;

    if (self.vtable.on_focus_callback) |on_focus_callback| {
        on_focus_callback(self.ptr);
    }
}

fn onBlur(ptr: *anyopaque) !void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.is_focused = false;

    if (self.vtable.on_blur_callback) |on_blur_callback| {
        try on_blur_callback(self.ptr, self.edit_buf.items);
    }
}

fn renderInteractiveInput(self: *Self) !void {
    var cursor_color = theme.cwdInput.text;
    cursor_color[3] = if (@mod(@as(i32, @intFromFloat(rl.getTime())), 2) == 0) 0 else 255;

    const absolute_path = &self.edit_buf;
    const cursor_utf_byte_position = self.cursor_utf_byte_position orelse 0;

    if (self.cursor_utf_byte_position) |*cursor_pos| {
        try Utils.text.handleKeyboardInputs(
            absolute_path,
            cursor_pos,
            .{
                .ptr = self,
                .call = onBlur,
            },
        );
    }

    const before_cursor = absolute_path.items[0..(if (absolute_path.items.len >= cursor_utf_byte_position) cursor_utf_byte_position else 0)];
    const after_cursor = absolute_path.items[(if (absolute_path.items.len >= cursor_utf_byte_position) cursor_utf_byte_position else 0)..];

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
    const cwd_input_id = cl.ElementId.localID(self.id_suffix);
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
            } else if (self.is_focused) {
                try onBlur(self);
            }
        }

        if (self.is_focused) {
            try self.renderInteractiveInput();
        } else if (self.source_buf) |source_buf| {
            cl.text(source_buf, cl.TextElementConfig{
                .font_size = 24,
                .color = theme.cwdInput.text,
            });
        }
    });
}
