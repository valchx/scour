const std = @import("std");
const cl = @import("zclay");

const theme = @import("../theme.zig");

const Props = struct {
    name: []const u8,
    type: std.fs.File.Kind,
    selected: bool,
};

pub fn render(props: Props, index: u32) void {
    cl.UI()(.{
        .id = .IDI("File", index),
        .layout = cl.LayoutConfig{
            .sizing = .{ .w = .grow, .h = .fixed(50) },
            .padding = .{ .left = 16 },
            .child_alignment = .{ .x = .left, .y = .center },
        },
        .background_color = if (props.selected) theme.fileItem.primary else theme.fileItem.secondary,
    })({
        cl.text(props.name, .{ .font_size = 24, .color = theme.text.primary });
    });
}
