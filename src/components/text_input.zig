const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const Utils = @import("../utils.zig");
const theme = @import("../theme.zig");

pub fn TextInput(comptime Context: type) type {
    return struct {
        const Self = @This();

        buf: std.ArrayList(u8),
        is_focused: bool = false,
        cursor_utf_byte_position: usize,
        _allocator: std.mem.Allocator,
        id_suffix: []const u8,
        on_blur_callback: Utils.Callback(Context),

        pub fn init(
            allocator: std.mem.Allocator,
            id_suffix: []const u8,
            on_blur_callback: Utils.Callback(Context),
        ) Self {
            return Self{
                ._allocator = allocator,
                .cursor_utf_byte_position = 0,
                .buf = std.ArrayList(u8).init(allocator),
                .id_suffix = id_suffix,
                .on_blur_callback = on_blur_callback,
            };
        }

        pub fn deinit(self: Self) void {
            self.buf.deinit();
        }

        fn onFocus(self: *Self) !void {
            self.*.is_focused = true;

            // TODO : Delect click position.
            self.*.cursor_utf_byte_position = self.buf.items.len;
        }

        fn onBlur(self: *Self) !void {
            self.*.is_focused = false;
            try self.on_blur_callback.invoke();
        }

        pub fn render(self: *Self) !void {
            const id = cl.ElementId.localID(self.id_suffix);
            cl.UI()(cl.ElementDeclaration{
                .id = id,
                .layout = .{
                    .direction = .left_to_right,
                    .sizing = .{ .h = .fit, .w = .grow },
                    .padding = .all(8),
                    .child_alignment = .{ .x = .left, .y = .center },
                },
                .background_color = theme.cwdInput.background,
            })({
                if (rl.isMouseButtonPressed(.left)) {
                    if (cl.pointerOver(id)) {
                        if (!self.is_focused) {
                            try self.*.onFocus();
                        }
                    } else {
                        try self.*.onBlur();
                    }
                }

                if (self.is_focused) {
                    var cursor_color = theme.cwdInput.text;
                    cursor_color[3] = if (@mod(@as(i32, @intFromFloat(rl.getTime())), 2) == 0) 0 else 255;

                    const buf = &self.buf;
                    const cursor_utf_byte_position = &self.cursor_utf_byte_position;

                    try Utils.text.handleKeyboardInputs(
                        buf,
                        cursor_utf_byte_position,
                        Utils.Callback(*Self){
                            .ctx = self,
                            .call = onBlur,
                        },
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
            });
        }
    };
}
