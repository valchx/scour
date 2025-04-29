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
cursor_pos: u32,
_allocator: std.mem.Allocator,

pub fn init(
    allocator: std.mem.Allocator,
    cwd_absolute_path: []const u8,
) Self {
    return Self{
        ._allocator = allocator,
        .cwd_absolute_path = cwd_absolute_path,
        .cursor_pos = @intCast(cwd_absolute_path.len),
    };
}

pub fn deinit(self: Self) void {
    if (self.temp_cwd_absolute_path) |temp_cwd_absolute_path| {
        temp_cwd_absolute_path.deinit();
    }
}

fn onClick(self: *Self) !void {
    if (!self.is_focused) {
        self.*.is_focused = true;
        if (self.temp_cwd_absolute_path) |temp_cwd_absolute_path| {
            temp_cwd_absolute_path.deinit();
        }
        self.*.temp_cwd_absolute_path = try std.ArrayList(u8).initCapacity(self._allocator, self.cwd_absolute_path.len);
    }
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
        if (rl.isMouseButtonPressed(.left) and cl.pointerOver(cwd_input_id)) {
            try self.*.onClick();
        }

        if (self.is_focused) {
            var cursor_color = theme.cwdInput.text;
            cursor_color[3] = if (@mod(@as(i32, @intFromFloat(rl.getTime())), 2) == 0) 0 else 255;

            const absolute_path = if (self.temp_cwd_absolute_path != null) self.temp_cwd_absolute_path.?.items else self.cwd_absolute_path;

            key_poll: while (true) {
                const key = rl.getKeyPressed();
                if (key == .null) {
                    break :key_poll;
                }
                if (key == .left and self.cursor_pos > 0) {
                    self.*.cursor_pos -= 1;
                }
                if (key == .right and self.cursor_pos < absolute_path.len) {
                    self.*.cursor_pos += 1;
                }
                if (key == .backspace and self.cursor_pos > 0) {
                    try self.temp_cwd_absolute_path.?.resize(self.temp_cwd_absolute_path.?.items.len -
                        1);
                    self.*.cursor_pos -= 1;
                }

                // TODO : This is awful. There must be some lib to free me from this.
                const key_int: u32 = @intCast(@intFromEnum(key));
                if (key_int <= std.math.maxInt(u8)) {
                    var ascii_key: u8 = @intCast(@intFromEnum(key));
                    if (std.ascii.isAscii(ascii_key)) {

                        // TODO : Caps lock ?
                        // Uppercase if shift is pressed
                        if (!(rl.isKeyDown(.right_shift) or rl.isKeyDown(.left_shift)) and std.ascii.isAlphabetic(ascii_key)) {
                            ascii_key += 32;
                        }

                        try self.temp_cwd_absolute_path.?.append(ascii_key);
                        self.*.cursor_pos += 1;
                    }
                }
            }

            const before_cursor = absolute_path[0..(if (absolute_path.len >= self.cursor_pos) self.cursor_pos else 0)];
            const after_cursor = absolute_path[(if (absolute_path.len >= self.cursor_pos) self.cursor_pos else 0)..];

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
        } else {
            cl.text(self.cwd_absolute_path, cl.TextElementConfig{
                .font_size = 24,
                .color = theme.cwdInput.text,
            });
        }
    });
}
