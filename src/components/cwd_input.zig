const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const Utils = @import("../utils.zig");
const theme = @import("../theme.zig");

const EntryList = @import("./entry_list.zig");

const Self = @This();

cwd_absolute_path: []const u8,

pub fn init(
    cwd_absolute_path: []const u8,
) Self {
    return Self{
        .cwd_absolute_path = cwd_absolute_path,
    };
}

pub fn render(self: Self) void {
    cl.UI()(cl.ElementDeclaration{
        .id = .ID("cwd-input-container"),
        .layout = .{
            .direction = .left_to_right,
            .sizing = .{ .h = .fit, .w = .grow },
            .padding = .all(8),
            .child_alignment = .{ .x = .left, .y = .center },
        },
        .background_color = theme.cwdInput.background,
    })({
        cl.text(self.cwd_absolute_path, cl.TextElementConfig{
            .font_size = 24,
            .color = theme.cwdInput.text,
        });
    });
}
