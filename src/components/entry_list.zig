const std = @import("std");
const cl = @import("zclay");

const theme = @import("../theme.zig");

const Entry = @import("./entry.zig");

pub const Props = struct {
    entries: [] Entry,
};

pub fn render(props: Props) void {
    cl.UI()(.{
        .id = .ID("EntryListOuterContainer"),
        .layout = .{ .direction = .left_to_right, .sizing = .grow, .padding = .all(16), .child_gap = 16 },
        .background_color = theme.background.primary,
    })({
        cl.UI()(.{
            .id = .ID("EntryList"),
            .layout = .{
                .direction = .top_to_bottom,
                .sizing = .{ .h = .grow, .w = .grow },
                .padding = .all(16),
                .child_alignment = .{ .x = .center, .y = .top },
                .child_gap = 2,
            },
            .background_color = theme.background.secondary,
        })({
            for (props.entries, 0..) |entry, i| {
                entry.render(@intCast(i));
            }
        });
    });
}
