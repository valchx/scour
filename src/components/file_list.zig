const cl = @import("zclay");

const theme = @import("../theme.zig");

const file = @import("./file.zig");

pub fn render() void {
    cl.UI()(.{
        .id = .ID("FileListOuterContainer"),
        .layout = .{ .direction = .left_to_right, .sizing = .grow, .padding = .all(16), .child_gap = 16 },
        .background_color = theme.background.primary,
    })({
        cl.UI()(.{
            .id = .ID("FileList"),
            .layout = .{
                .direction = .top_to_bottom,
                .sizing = .{ .h = .grow, .w = .grow },
                .padding = .all(16),
                .child_alignment = .{ .x = .center, .y = .top },
                .child_gap = 2,
            },
            .background_color = theme.background.secondary,
        })({
            for (0..5) |i| file.render(.{
                .name = "Some file",
                .type = .file,
                .selected = false,
            }, @intCast(i));
        });
    });
}
